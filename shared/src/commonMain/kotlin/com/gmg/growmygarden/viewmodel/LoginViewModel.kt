package com.gmg.growmygarden.viewmodel

import com.gmg.growmygarden.auth.LoginService
import com.gmg.growmygarden.auth.LoginStatus
import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesState
import com.rickclephas.kmp.observableviewmodel.ViewModel
import com.rickclephas.kmp.observableviewmodel.stateIn
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.parameter.parametersOf

class LoginViewModel : ViewModel(), KoinComponent {

    private val loginService: LoginService by inject { parametersOf(viewModelScope) }

    @NativeCoroutinesState
    val loginState: StateFlow<LoginStatus> = loginService.loginStatus.stateIn(
        viewModelScope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5000L),
        initialValue = LoginStatus.UNINITIALIZED,
    )
}
