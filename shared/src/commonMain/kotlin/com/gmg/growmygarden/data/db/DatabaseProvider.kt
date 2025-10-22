package com.gmg.growmygarden.data.db

import kotbase.Database
import kotlinx.coroutines.CoroutineName
import kotlinx.coroutines.CoroutineScope
import kotlin.coroutines.CoroutineContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO

class DatabaseProvider(
    val readContext: CoroutineContext = CoroutineName("db-read") + Dispatchers.IO,
    val writeContext: CoroutineContext = CoroutineName("db-write") + Dispatchers.IO.limitedParallelism(1),
    val scope: CoroutineScope = CoroutineScope(writeContext)
) {
    // Linked by Gradle, the IDE will claim an error. We can Ignore it
    @Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
    val database by lazy { Database(DB_NAME) }
    companion object {
        private const val DB_NAME = "grow-my-garden"
    }
}