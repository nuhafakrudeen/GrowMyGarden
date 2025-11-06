package com.gmg.growmygarden.auth

import dev.gitlive.firebase.Firebase
import dev.gitlive.firebase.auth.auth

class UserAuthProvider {
    val firebaseAuth by lazy { Firebase.auth }
}
