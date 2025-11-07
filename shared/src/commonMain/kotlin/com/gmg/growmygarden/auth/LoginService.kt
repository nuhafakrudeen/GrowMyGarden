package com.gmg.growmygarden.auth

import com.rickclephas.kmp.nativecoroutines.NativeCoroutines
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.consumeAsFlow

enum class LoginStatus {
    UNINITIALIZED,
    FAILED,
    AUTHENTICATED,
}
class LoginService(
    val scope: CoroutineScope,
    authProvider: UserAuthProvider = UserAuthProvider(),
) {

    private val auth = authProvider.firebaseAuth
    private val loginStatusChannel = Channel<LoginStatus>()

    @NativeCoroutines
    val loginStatus: Flow<LoginStatus>
        get() = loginStatusChannel.consumeAsFlow()

    @NativeCoroutines
    suspend fun loginEmailPassword(email: String, password: String) {
        val authRes = auth.signInWithEmailAndPassword(
            email,
            password,
        )

        if (authRes.user == null) {
            loginStatusChannel.trySend(LoginStatus.FAILED)
        }
    }
}
