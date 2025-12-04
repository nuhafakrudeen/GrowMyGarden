package com.gmg.growmygarden.auth

import kotlinx.serialization.Serializable

@Serializable
data class User(
    val id: String,
)

class UserManager {
    private var _user: User? = null
    val user: User?
        get() = _user

    fun login(
        userId: String,
    ) {
        _user = User(userId)
    }

    fun logout() {
        _user = null
    }
}
