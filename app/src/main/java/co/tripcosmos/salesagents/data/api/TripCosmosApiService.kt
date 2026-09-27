package co.tripcosmos.salesagents.data.api

import co.tripcosmos.salesagents.AppConfig
import co.tripcosmos.salesagents.BuildConfig
import co.tripcosmos.salesagents.data.model.*
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.*
import java.util.concurrent.TimeUnit

/** The plugin's mobile REST API. The token is added by [ApiClient]; endpoints never take it as a parameter. */
interface TripCosmosApiService {

    @GET("mobile/me") suspend fun me(): Response<MeResponse>
    @GET("mobile/dashboard") suspend fun dashboard(): Response<DashboardResponse>

    @GET("mobile/notifications")
    suspend fun notifications(
        @Query("since_lead") sinceLead: Long,
        @Query("since_msg") sinceMsg: Long
    ): Response<NotificationsResponse>

    @GET("mobile/calls")
    suspend fun calls(@Query("limit") limit: Int = 50, @Query("lead_id") leadId: Long? = null): Response<CallListResponse>

    // ---- leads
    @GET("mobile/leads/list")
    suspend fun leads(
        @Query("stage") stage: String? = null,
        @Query("owner") owner: String? = null,
        @Query("q") query: String? = null,
        @Query("sort") sort: String? = null,
        @Query("limit") limit: Int = 30,
        @Query("offset") offset: Int = 0
    ): Response<LeadListResponse>

    @GET("mobile/leads/{id}") suspend fun lead(@Path("id") id: Long): Response<LeadDetailResponse>
    @POST("mobile/leads/create") suspend fun createLead(@Body body: CreateLeadBody): Response<CreateLeadResponse>
    @POST("mobile/leads/{id}/summarize") suspend fun summarize(@Path("id") id: Long, @Body body: SummarizeBody): Response<SummaryResponse>
    @POST("mobile/update-lead") suspend fun updateLead(@Body body: UpdateLeadBody): Response<SimpleResponse>
    @POST("mobile/assign-lead") suspend fun assignLead(@Body body: AssignLeadBody): Response<SimpleResponse>

    // ---- tasks
    @GET("mobile/tasks")
    suspend fun tasks(
        @Query("filter") filter: String = "open",
        @Query("lead_id") leadId: Long? = null,
        @Query("limit") limit: Int = 100
    ): Response<TaskListResponse>

    @POST("mobile/tasks/create") suspend fun createTask(@Body body: CreateTaskBody): Response<TaskCreatedResponse>
    @POST("mobile/tasks/{id}/complete") suspend fun completeTask(@Path("id") id: Long): Response<SimpleResponse>

    // ---- trips: bookings, quotes, payments
    @GET("mobile/bookings")
    suspend fun bookings(@Query("lead_id") leadId: Long? = null, @Query("status") status: String? = null): Response<BookingListResponse>

    @POST("mobile/bookings/save") suspend fun saveBooking(@Body body: SaveBookingBody): Response<BookingResponse>
    @POST("mobile/quotes/create") suspend fun createQuote(@Body body: CreateQuoteBody): Response<BookingResponse>
    @POST("mobile/quotes/{id}/send") suspend fun sendQuote(@Path("id") id: Long): Response<SimpleResponse>
    @POST("mobile/payments/link") suspend fun paymentLink(@Body body: PaymentLinkBody): Response<PaymentLinkResponse>
    @POST("mobile/payments/record") suspend fun recordPayment(@Body body: RecordPaymentBody): Response<BookingResponse>
    @POST("mobile/send-dispatch") suspend fun sendDispatch(@Body body: DispatchBody): Response<SimpleResponse>

    // ---- WhatsApp
    @GET("mobile/whatsapp-leads") suspend fun inbox(@Query("limit") limit: Int = 50): Response<InboxResponse>

    @GET("mobile/conversations/{id}")
    suspend fun conversation(@Path("id") id: Long, @Query("limit") limit: Int = 100): Response<ConversationResponse>

    @POST("mobile/conversations/{id}/reply") suspend fun reply(@Path("id") id: Long, @Body body: ReplyBody): Response<SimpleResponse>
    @POST("mobile/conversations/{id}/ai") suspend fun setAi(@Path("id") id: Long, @Body body: AiToggleBody): Response<AiToggleResponse>
    @POST("mobile/quick-action") suspend fun quickAction(@Body body: QuickActionBody): Response<SimpleResponse>

    // ---- calls
    @GET("mobile/caller-id") suspend fun callerId(@Query("phone") phone: String): Response<CallerIdResponse>
    @POST("mobile/call-log") suspend fun logCall(@Body body: CallLogPayload): Response<SimpleResponse>
}

/** Builds (and rebuilds when the server URL changes) the Retrofit client. */
object ApiClient {

    @Volatile private var cachedUrl: String = ""
    @Volatile private var cached: TripCosmosApiService? = null

    fun get(baseUrl: String = AppConfig.baseUrl()): TripCosmosApiService {
        val existing = cached
        if (existing != null && cachedUrl == baseUrl) return existing
        return synchronized(this) {
            val again = cached
            if (again != null && cachedUrl == baseUrl) again else build(baseUrl).also {
                cached = it
                cachedUrl = baseUrl
            }
        }
    }

    private fun build(baseUrl: String): TripCosmosApiService {
        val logger = HttpLoggingInterceptor().apply {
            level = if (BuildConfig.DEBUG) HttpLoggingInterceptor.Level.BASIC else HttpLoggingInterceptor.Level.NONE
            redactHeader("X-Mobile-Token")
        }
        val auth = Interceptor { chain ->
            val builder = chain.request().newBuilder().header("Accept", "application/json")
            val token = AppConfig.token()
            if (token.isNotBlank()) builder.header("X-Mobile-Token", token)
            chain.proceed(builder.build())
        }
        val client = OkHttpClient.Builder()
            .addInterceptor(auth)
            .addInterceptor(logger)
            .connectTimeout(15, TimeUnit.SECONDS)
            // The AI summary can take a while; everything else answers well inside this.
            .readTimeout(45, TimeUnit.SECONDS)
            .build()
        return Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TripCosmosApiService::class.java)
    }

    /** Test/pairing helper: a client for a URL + token that are not saved yet. */
    fun forPairing(baseUrl: String, token: String): TripCosmosApiService {
        val client = OkHttpClient.Builder()
            .addInterceptor { it.proceed(it.request().newBuilder().header("X-Mobile-Token", token.trim()).header("Accept", "application/json").build()) }
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(20, TimeUnit.SECONDS)
            .build()
        return Retrofit.Builder()
            .baseUrl(AppConfig.normalizeBaseUrl(baseUrl))
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(TripCosmosApiService::class.java)
    }
}
