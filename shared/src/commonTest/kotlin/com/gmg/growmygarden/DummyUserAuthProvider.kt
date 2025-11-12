package com.gmg.growmygarden

import co.touchlab.kermit.Logger
import com.gmg.growmygarden.auth.LoginStatus
import com.gmg.growmygarden.auth.User
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines
import dev.gitlive.firebase.auth.FirebaseAuthException
import dev.gitlive.firebase.auth.FirebaseUser
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.consumeAsFlow

class DummyUserAuthProvider {

    private val log = Logger.withTag("UserAuthentication")
    private val loginStatusChannel = Channel<LoginStatus>()

    val user: User?
        get() = null

    private fun firebaseUserToUser(firebaseUser: FirebaseUser): User {
        return User(
            displayName = firebaseUser.displayName ?: "",
            email = firebaseUser.email ?: "",
            uid = firebaseUser.uid,
        )
    }

    @NativeCoroutines
    val loginStatus: Flow<LoginStatus>
        get() = loginStatusChannel.consumeAsFlow()

    private fun handleAuthError(authError: FirebaseAuthException) {
        val errorMessage = authError.message?.lowercase() ?: ""
        when {
            errorMessage.contains("invalid-email") || errorMessage.contains("badly formatted") -> {
                log.i { "Login Failed: Invalid Email" }
                loginStatusChannel.trySend(LoginStatus.ERROR_INVALID_EMAIL)
            }

            errorMessage.contains("user-not-found") || errorMessage.contains("no user record") || errorMessage.contains(
                "user-disabled",
            ) -> {
                log.i { "Login Failed: User Not Found" }
                loginStatusChannel.trySend(LoginStatus.ERROR_USER_NOT_FOUND)
            }

            errorMessage.contains("wrong-password") || errorMessage.contains("invalid-credential") || errorMessage.contains(
                "invalid-password",
            ) -> {
                log.i { "Login Failed: Invalid Credentials" }
                loginStatusChannel.trySend(LoginStatus.ERROR_WRONG_CREDENTIALS)
            }

            errorMessage.contains("too-many-requests") -> {
                log.i { "Login Failed: Too Many Login Attempts" }
                loginStatusChannel.trySend(LoginStatus.ERROR_TOO_MANY_REQUESTS)
            }

            errorMessage.contains("network") || errorMessage.contains("connection") -> {
                log.i { "Login Failed: Network Failed" }
                loginStatusChannel.trySend(LoginStatus.ERROR_NETWORK_REQUEST_FAILED)
            }

            else -> {
                log.e(authError) { "Unhandled auth error: ${authError.message}" }
                loginStatusChannel.trySend(LoginStatus.ERROR_UNKNOWN)
            }
        }
    }

    @NativeCoroutines
    suspend fun createNewUser(
        email: String,
        password: String,
        displayName: String,
    ) {
        return
    }

    @NativeCoroutines
    suspend fun loginGoogle(
        idToken: String,
        accessToken: String,
    ) {
        return
    }

    @NativeCoroutines
    suspend fun loginApple(
        idToken: String,
        rawNonce: String? = null,
    ) {
        return
    }

    @NativeCoroutines
    suspend fun loginEmailPassword(email: String, password: String) {
        return
    }
}
