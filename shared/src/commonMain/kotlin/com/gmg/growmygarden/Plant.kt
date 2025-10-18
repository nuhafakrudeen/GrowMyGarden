package com.gmg.growmygarden

import io.realm.kotlin.types.RealmObject
import io.realm.kotlin.types.annotations.Ignore
import io.realm.kotlin.types.annotations.PersistedName
import io.realm.kotlin.types.annotations.PrimaryKey
import org.mongodb.kbson.ObjectId
import kotlin.time.Duration

/**
 * name of plant (users choice)
 * scientific name of the plant -> for dashboard
 * species of the plant (for the plantbook)
 * how much and how often to water the plant
 * */
internal class Plant(var name: String? = null, var species: String? = null, wateringFrequency: Duration): RealmObject {
    constructor(): this(null, null, Duration.INFINITE)
    @PrimaryKey
    var _id: ObjectId = ObjectId()
    @PersistedName("wateringFrequency")
    private var _wateringFrequency: String = ""
    @Ignore
    var wateringFrequency: Duration
        get() {
            return Duration.parse(_wateringFrequency)
        }
        set(duration: Duration) {
            this._wateringFrequency = Duration.toString()
        }
    @PersistedName("fertilizingFrequency")
    private var _fertilizingFrequency: String = ""

    @Ignore
    var fertilizingFrequency: Duration
        get() {
            return Duration.parse(this._fertilizingFrequency)
        }
        set(duration: Duration) {
            this._fertilizingFrequency = duration.toString()
        }


    init {
        this.wateringFrequency = wateringFrequency
    }
}


