package co.tripcosmos.salesagents.data

import co.tripcosmos.salesagents.data.api.ApiClient
import co.tripcosmos.salesagents.data.db.CacheDao
import co.tripcosmos.salesagents.data.db.CacheEntry
import co.tripcosmos.salesagents.data.repo.Repository
import co.tripcosmos.salesagents.data.repo.Res
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.SocketPolicy
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

class RepositoryTest {

    private class FakeCache : CacheDao {
        val rows = mutableMapOf<String, CacheEntry>()
        override suspend fun get(key: String) = rows[key]
        override suspend fun put(entry: CacheEntry) { rows[entry.key] = entry }
        override suspend fun clear() { rows.clear() }
        override suspend fun deleteOlderThan(before: Long) {}
    }

    private lateinit var server: MockWebServer
    private lateinit var cache: FakeCache
    private lateinit var repo: Repository

    @Before fun setUp() {
        server = MockWebServer().also { it.start() }
        cache = FakeCache()
        repo = Repository(cache, { ApiClient.forPairing(server.url("/wp-json/tc-agents/v1/").toString(), "tok-123") })
    }

    @After fun tearDown() = server.shutdown()

    private fun reply(code: Int, body: String) =
        server.enqueue(MockResponse().setResponseCode(code).setHeader("Content-Type", "application/json").setBody(body))

    @Test fun `success is returned, cached, and sent with the token header`() = runBlocking {
        reply(200, """{"ok":true,"agent":"Santosh"}""")
        val res = repo.me()
        assertTrue(res is Res.Ok)
        assertEquals("Santosh", repo.cachedMe()!!.agent)
        val sent = server.takeRequest()
        assertEquals("/wp-json/tc-agents/v1/mobile/me", sent.path)
        assertEquals("tok-123", sent.getHeader("X-Mobile-Token"))
    }

    @Test fun `server validation errors surface the servers own message`() = runBlocking {
        reply(400, """{"ok":false,"error":"A valid phone number is required."}""")
        val res = repo.me() as Res.Err
        assertEquals("A valid phone number is required.", res.message)
        assertEquals(Res.Kind.VALIDATION, res.kind)
    }

    @Test fun `wordpress core errors are read from message`() = runBlocking {
        reply(404, """{"code":"rest_no_route","message":"No route was found."}""")
        assertEquals("No route was found.", (repo.me() as Res.Err).message)
    }

    @Test fun `a rejected token is announced so the app can re-pair`() = runBlocking {
        reply(401, """{"code":"rest_forbidden","message":"Sorry"}""")
        var announced = 0
        val job = GlobalScope.launch(Dispatchers.Unconfined, CoroutineStart.UNDISPATCHED) { repo.authFailed.collect { announced++ } }
        val res = repo.me() as Res.Err
        job.cancel()
        assertEquals(Res.Kind.AUTH, res.kind)
        assertEquals(1, announced)
    }

    @Test fun `no network is a friendly error and leaves cached data readable`() = runBlocking {
        cache.put(CacheEntry("dashboard", """{"ok":true,"today":{"new_leads":4}}"""))
        server.enqueue(MockResponse().setSocketPolicy(SocketPolicy.DISCONNECT_AT_START))
        val res = repo.dashboard() as Res.Err
        assertEquals(Res.Kind.NETWORK, res.kind)
        assertEquals(4, repo.cachedDashboard()!!.today.newLeads)
    }

    @Test fun `a non-json error body still gives a useful message`() = runBlocking {
        reply(500, "<html>boom</html>")
        val res = repo.me() as Res.Err
        assertTrue(res.message.contains("500"))
        assertEquals(Res.Kind.SERVER, res.kind)
    }

    @Test fun `ok false with http 200 is treated as a failure`() = runBlocking {
        reply(200, """{"ok":false,"error":"Lead not found"}""")
        assertEquals("Lead not found", (repo.lead(99) as Res.Err).message)
    }

    @Test fun `only the unfiltered first page of leads is cached`() = runBlocking {
        reply(200, """{"ok":true,"leads":[{"id":1,"name":"A"}],"total":1,"has_more":false}""")
        repo.leads(stage = "all", owner = null, query = null, sort = null, offset = 0)
        assertNotNull(repo.cachedLeads())

        val other = FakeCache()
        val filtered = Repository(other, { ApiClient.forPairing(server.url("/wp-json/tc-agents/v1/").toString(), "t") })
        reply(200, """{"ok":true,"leads":[],"total":0,"has_more":false}""")
        filtered.leads(stage = "won", owner = null, query = null, sort = null, offset = 0)
        assertNull(filtered.cachedLeads())
        server.takeRequest() // first request
        val second = server.takeRequest()
        assertTrue(second.path!!.contains("stage=won"))
    }

    @Test fun `filters are sent as query parameters and blank ones are omitted`() = runBlocking {
        reply(200, """{"ok":true,"leads":[],"total":0,"has_more":false}""")
        repo.leads(stage = "all", owner = "me", query = "  ", sort = "score", offset = 30)
        val path = server.takeRequest().path!!
        assertTrue(path, path.contains("owner=me")); assertTrue(path, path.contains("sort=score")); assertTrue(path, path.contains("offset=30"))
        assertFalse(path, path.contains("stage=")); assertFalse(path, path.contains("q="))
    }
}
