package com.gmg.growmygarden

import io.realm.kotlin.Realm
import io.realm.kotlin.RealmConfiguration

expect fun getRealmPath(): String
private val realmConfig = RealmConfiguration.Builder(
    schema = setOf(Plant::class)
).directory(getRealmPath()).build()


internal val realm = Realm.open(realmConfig)

object Database {
    fun getRealm() : Realm {
        return realm
    }
}