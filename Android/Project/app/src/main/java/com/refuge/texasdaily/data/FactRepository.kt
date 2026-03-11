package com.refuge.texasdaily.data

import android.content.Context
import com.google.gson.Gson
import com.refuge.texasdaily.R

class FactRepository(private val context: Context) {

    private val allFacts: List<TexasFact> by lazy {
        val json = context.resources.openRawResource(R.raw.texas_facts)
            .bufferedReader()
            .use { it.readText() }
        Gson().fromJson(json, FactsWrapper::class.java).facts
    }

    fun getCategories(): List<String> =
        allFacts.map { it.category }.distinct().sorted()

    fun randomFact(selectedCategories: Set<String>): TexasFact {
        val pool = if (selectedCategories.isEmpty()) {
            allFacts
        } else {
            allFacts.filter { it.category in selectedCategories }
        }
        return pool.random()
    }
}
