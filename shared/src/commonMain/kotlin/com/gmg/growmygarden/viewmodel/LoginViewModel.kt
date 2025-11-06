package com.gmg.growmygarden.viewmodel

import com.rickclephas.kmp.nativecoroutines.NativeCoroutinesState
import com.rickclephas.kmp.observableviewmodel.ViewModel
import kotlinx.coroutines.flow.StateFlow

class LoginViewModel : ViewModel() {
    @NativeCoroutinesState
    val loginState: StateFlow<LoginStatus>
}
