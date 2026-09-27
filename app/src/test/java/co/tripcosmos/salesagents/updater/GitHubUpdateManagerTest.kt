package co.tripcosmos.salesagents.updater

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class GitHubUpdateManagerTest {

    @Test
    fun compareVersions_handlesPrefixesAndLength() {
        assertTrue(GitHubUpdateManager.compareVersions("app-v2.1.0", "v2.0.1") > 0)
        assertTrue(GitHubUpdateManager.compareVersions("v2.0.1", "v2.0.1") == 0)
        assertTrue(GitHubUpdateManager.compareVersions("app-v2.0", "v2.0.0") == 0)
        assertTrue(GitHubUpdateManager.compareVersions("v1.9.9", "v2.0.0") < 0)
        assertTrue(GitHubUpdateManager.compareVersions("v2.10.0", "v2.9.0") > 0)
    }

    @Test
    fun getZipUrl_onlyTrustsGithubHosts() {
        val rel = { u: String -> mapOf("assets" to emptyList<Map<String, String>>(), "zipball_url" to u) }
        assertNotNull(GitHubUpdateManager.getZipUrl(rel("https://github.com/o/r/archive/v1.zip")))
        assertNotNull(GitHubUpdateManager.getZipUrl(rel("https://api.github.com/repos/o/r/zipball/v1")))
        assertNull(GitHubUpdateManager.getZipUrl(rel("http://github.com/o/r/archive/v1.zip")))
        assertNull(GitHubUpdateManager.getZipUrl(rel("https://evil.example.com/v1.zip")))
        assertNull(GitHubUpdateManager.getZipUrl(rel("https://github.com.evil.example/v1.zip")))
    }

    @Test
    fun getZipUrl_prefersAssetOverZipball() {
        val rel = mapOf(
            "assets" to listOf(mapOf("name" to "p.zip", "browser_download_url" to "https://github.com/o/r/releases/download/v1/p.zip")),
            "zipball_url" to "https://api.github.com/x"
        )
        assertEquals("https://github.com/o/r/releases/download/v1/p.zip", GitHubUpdateManager.getZipUrl(rel))
    }

    @Test
    fun parseLatestAppRelease_picksNewestAppTaggedRelease_ignoringPluginTags() {
        val body = """
            [
              {"tag_name": "v1.9.0", "name": "Plugin 1.9.0", "draft": false, "assets": [], "zipball_url": "https://api.github.com/plugin"},
              {"tag_name": "app-v2.0.0", "name": "App 2.0.0", "body": "old", "draft": false,
               "assets": [{"name": "app.zip", "browser_download_url": "https://github.com/tripcosmosco/agents/releases/download/app-v2.0.0/app.zip"}],
               "zipball_url": "https://api.github.com/old"},
              {"tag_name": "app-v3.0.0", "name": "App 3.0.0", "body": "new", "draft": false,
               "assets": [{"name": "app.zip", "browser_download_url": "https://github.com/tripcosmosco/agents/releases/download/app-v3.0.0/app.zip"}],
               "zipball_url": "https://api.github.com/new"},
              {"tag_name": "app-v2.9.0", "name": "App 2.9.0 draft", "draft": true, "assets": [], "zipball_url": "https://api.github.com/draft"}
            ]
        """.trimIndent()
        val info = GitHubUpdateManager.parseLatestAppRelease(body)!!
        assertEquals("app-v3.0.0", info.tagName)
        assertEquals("https://github.com/tripcosmosco/agents/releases/download/app-v3.0.0/app.zip", info.downloadUrl)
    }

    @Test
    fun parseLatestAppRelease_noAppTagPresent_returnsNull() {
        assertNull(GitHubUpdateManager.parseLatestAppRelease("""[{"tag_name": "v1.0.0", "draft": false}]"""))
    }
}
