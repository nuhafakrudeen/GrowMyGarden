package com.gmg.growmygarden.data.db

import kotbase.Database
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineName
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlin.coroutines.CoroutineContext

class DatabaseProvider(
    val dispatcher: CoroutineDispatcher = Dispatchers.IO,
    val readContext: CoroutineContext = CoroutineName("db-read") + dispatcher,
    val writeContext: CoroutineContext = CoroutineName("db-write") + dispatcher.limitedParallelism(1),
    val scope: CoroutineScope = CoroutineScope(writeContext),
) {
    // Linked by Gradle, the IDE will claim an error. We can Ignore it
    @Suppress("MISSING_DEPENDENCY_SUPERCLASS_IN_TYPE_ARGUMENT")
    val database by lazy { Database(DB_NAME) }
    companion object {
        private const val DB_NAME = "grow-my-garden"
    }
}
