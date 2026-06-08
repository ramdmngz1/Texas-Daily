package com.refuge.texasdaily.data

import android.content.Context
import com.google.gson.Gson
import com.refuge.texasdaily.R

class FactRepository private constructor(context: Context) {

    private val appContext: Context = context.applicationContext

    private val allFacts: List<TexasFact> by lazy {
        val json = appContext.resources.openRawResource(R.raw.texas_facts)
            .bufferedReader()
            .use { it.readText() }
        Gson().fromJson(json, FactsWrapper::class.java).facts
    }

    private val categoryIndex: Map<String, List<TexasFact>> by lazy {
        allFacts.groupBy { it.category }
    }

    fun getCategories(): List<String> =
        categoryIndex.keys.sorted()

    fun randomFact(selectedCategories: Set<String>, excludingId: Int? = null): TexasFact? {
        val pool = if (selectedCategories.isEmpty()) {
            allFacts
        } else {
            selectedCategories.flatMap { categoryIndex[it].orEmpty() }
        }
        if (pool.isEmpty()) return null

        if (excludingId != null) {
            val filtered = pool.filter { it.id != excludingId }
            if (filtered.isNotEmpty()) return filtered.random()
        }

        return pool.random()
    }

    companion object {
        @Volatile
        private var instance: FactRepository? = null

        fun getInstance(context: Context): FactRepository {
            return instance ?: synchronized(this) {
                instance ?: FactRepository(context.applicationContext).also { instance = it }
            }
        }
    }
}
