package com.gmg.growmygarden.viewmodel

import com.gmg.growmygarden.auth.UserManager
import com.rickclephas.kmp.observableviewmodel.ViewModel

class LoginViewModel(
    private val userManager: UserManager,
) : ViewModel() {

    fun login(userId: String) {
        userManager.login(userId)
    }

    fun logout() {
        userManager.logout()
    }
}
