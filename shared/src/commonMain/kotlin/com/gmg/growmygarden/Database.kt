package com.gmg.growmygarden

import io.realm.kotlin.Realm
import io.realm.kotlin.RealmConfiguration

private val realmConfig = RealmConfiguration.create(
    schema = setOf(Plant::class)
)


internal val realm = Realm.open(realmConfig)

object Database {
    fun getRealm() : Realm {
        return realm
    }
}