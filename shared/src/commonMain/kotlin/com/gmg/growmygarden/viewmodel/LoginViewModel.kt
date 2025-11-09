package com.gmg.growmygarden.viewmodel

import com.gmg.growmygarden.auth.LoginStatus
import com.gmg.growmygarden.auth.UserAuthProvider
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesState
import com.rickclephas.kmp.observableviewmodel.ViewModel
import com.rickclephas.kmp.observableviewmodel.launch
import com.rickclephas.kmp.observableviewmodel.stateIn
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow

class LoginViewModel(
    private val userAuthProvider: UserAuthProvider,
) : ViewModel() {

    @NativeCoroutinesState
    val loginState: StateFlow<LoginStatus> = userAuthProvider.loginStatus.stateIn(
        viewModelScope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000L),
        initialValue = LoginStatus.UNINITIALIZED,
    )

    fun createNewUser(
        email: String,
        password: String,
        displayName: String,
    ) {
        viewModelScope.launch {
            userAuthProvider.createNewUser(
                email,
                password,
                displayName,
            )
        }
    }

    fun loginEmailPassword(email: String, password: String) {
        viewModelScope.launch {
            userAuthProvider.loginEmailPassword(
                email,
                password,
            )
        }
    }

    fun loginGoogle(
        idToken: String,
        accessToken: String,
    ) {
        viewModelScope.launch {
            userAuthProvider.loginGoogle(idToken, accessToken)
        }
    }

    fun loginApple(
        idToken: String,
        rawNonce: String,
    ) {
        viewModelScope.launch {
            userAuthProvider.loginApple(
                idToken,
                rawNonce,
            )
        }
    }
}
