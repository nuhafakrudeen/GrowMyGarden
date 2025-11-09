package com.gmg.growmygarden.auth

import co.touchlab.kermit.Logger
import com.rickclephas.kmp.nativecoroutines.NativeCoroutines
import dev.gitlive.firebase.Firebase
import dev.gitlive.firebase.auth.FirebaseAuthException
import dev.gitlive.firebase.auth.FirebaseUser
import dev.gitlive.firebase.auth.GoogleAuthProvider
import dev.gitlive.firebase.auth.OAuthProvider
import dev.gitlive.firebase.auth.auth
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.consumeAsFlow
import kotlinx.serialization.Serializable

enum class LoginStatus {
    UNINITIALIZED,
    AUTHENTICATED,

    // Errors
    ERROR_INVALID_EMAIL,
    ERROR_NETWORK_REQUEST_FAILED,
    ERROR_TOO_MANY_REQUESTS,
    ERROR_UNKNOWN,

    // User Login
    ERROR_USER_NOT_FOUND,
    ERROR_WRONG_CREDENTIALS,

    // User Create
    ERROR_WEAK_PASSWORD,
    ERROR_EMAIL_ALREADY_IN_USE,
}

@Serializable
data class User(
    val displayName: String = "",
    val email: String = "",
    val uid: String = "",
)

class UserAuthProvider {

    private val log = Logger.withTag("UserAuthentication")
    val auth by lazy { Firebase.auth }
    private val loginStatusChannel = Channel<LoginStatus>()

    val user: User?
        get() = auth.currentUser?.let(::firebaseUserToUser)

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
        try {
            auth.createUserWithEmailAndPassword(
                email = email,
                password = password,
            )
            loginEmailPassword(email, password)
            auth.currentUser?.updateProfile(
                displayName,
            )
        } catch (authError: FirebaseAuthException) {
            val errorMessage = authError.message?.lowercase() ?: ""
            when {
                errorMessage.contains("email-already-in-use") ||
                    errorMessage.contains("already in use") -> {
                    log.i { "Registration Failed: Email Already In Use" }
                    loginStatusChannel.trySend(LoginStatus.ERROR_EMAIL_ALREADY_IN_USE)
                }

                errorMessage.contains("invalid-email") ||
                    errorMessage.contains("badly formatted") -> {
                    log.i { "Registration Failed: Invalid Email" }
                    loginStatusChannel.trySend(LoginStatus.ERROR_INVALID_EMAIL)
                }

                errorMessage.contains("weak-password") ||
                    errorMessage.contains("password should be at least") -> {
                    log.i { "Registration Failed: Weak Password" }
                    loginStatusChannel.trySend(LoginStatus.ERROR_WEAK_PASSWORD)
                }

                errorMessage.contains("network") ||
                    errorMessage.contains("connection") -> {
                    log.i { "Registration Failed: Network Failed" }
                    loginStatusChannel.trySend(LoginStatus.ERROR_NETWORK_REQUEST_FAILED)
                }

                else -> {
                    log.e(authError) { "Unhandled registration error: ${authError.message}" }
                    loginStatusChannel.trySend(LoginStatus.ERROR_UNKNOWN)
                }
            }
        } catch (e: Exception) {
            log.e(e) { "User Registration Failed With an unknown Exception" }
            loginStatusChannel.trySend(LoginStatus.ERROR_UNKNOWN)
        }
    }

    @NativeCoroutines
    suspend fun loginGoogle(
        idToken: String,
        accessToken: String,
    ) {
        try {
            val authResult = auth.signInWithCredential(
                GoogleAuthProvider.credential(
                    idToken,
                    accessToken,
                ),
            )
        } catch (authError: FirebaseAuthException) {
            handleAuthError(authError)
        } catch (e: Exception) {
            log.e(e) { "User Login Failed With an unknown Exception" }
            loginStatusChannel.trySend(LoginStatus.ERROR_UNKNOWN)
        }
    }

    @NativeCoroutines
    suspend fun loginApple(
        idToken: String,
        rawNonce: String? = null,
    ) {
        try {
            val authResult = auth.signInWithCredential(
                OAuthProvider.credential(
                    providerId = "apple.com",
                    idToken = idToken,
                    rawNonce = rawNonce,
                ),
            )
        } catch (authError: FirebaseAuthException) {
            handleAuthError(authError)
        } catch (e: Exception) {
            log.e(e) { "User Login Failed With an unknown Exception" }
            loginStatusChannel.trySend(LoginStatus.ERROR_UNKNOWN)
        }
    }

    @NativeCoroutines
    suspend fun loginEmailPassword(email: String, password: String) {
        try {
            val authResult = auth.signInWithEmailAndPassword(
                email,
                password,
            )
            loginStatusChannel.trySend(LoginStatus.AUTHENTICATED)
        } catch (authError: FirebaseAuthException) {
            handleAuthError(authError)
        } catch (e: Exception) {
            log.e(e) { "User Login Failed With an unknown Exception" }
            loginStatusChannel.trySend(LoginStatus.ERROR_UNKNOWN)
        }
    }
}
