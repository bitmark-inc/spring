/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.statistic

import android.content.Context
import android.os.Bundle
import androidx.annotation.StringDef
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.DividerItemDecoration
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.bitmark.fbm.R
import com.bitmark.fbm.data.model.entity.Period
import com.bitmark.fbm.data.source.remote.api.response.GetStatisticResponse
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.util.DateTimeUtil
import com.bitmark.fbm.util.modelview.SectionModelView
import com.google.gson.Gson
import kotlinx.android.synthetic.main.fragment_statistic.*
import java.util.*
import javax.inject.Inject


class StatisticFragment : BaseSupportFragment() {

    companion object {

        const val USAGE = "usage"

        const val INSIGHTS = "insights"

        @Retention(AnnotationRetention.SOURCE)
        @StringDef(USAGE, INSIGHTS)
        annotation class Type

        private const val TYPE = "type"

        private const val PERIOD = "period"

        fun newInstance(@Type type: String, period: Period): StatisticFragment {
            val fragment = StatisticFragment()
            val bundle = Bundle()
            bundle.putString(TYPE, type)
            bundle.putString(PERIOD, period.value)
            fragment.arguments = bundle
            return fragment
        }
    }

    @Inject
    internal lateinit var viewModel: StatisticViewModel

    @Inject
    internal lateinit var navigator: Navigator

    @Type
    private lateinit var type: String

    private lateinit var period: Period

    private val adapter = StatisticRecyclerViewAdapter()

    override fun layoutRes(): Int = R.layout.fragment_statistic

    override fun viewModel(): BaseViewModel? = viewModel

    override fun onAttach(context: Context) {
        super.onAttach(context)

        type = arguments?.getString(TYPE) ?: throw IllegalArgumentException("missing type")
        period = Period.fromString(
            arguments?.getString(PERIOD) ?: throw IllegalArgumentException("missing period")
        )
    }

    override fun initComponents() {
        super.initComponents()

        when (period) {
            Period.WEEK   -> {
                tvType.text = getString(R.string.last_week)
                val dateRange = DateTimeUtil.getDateRangeOfWeek(-1)
                tvTime.text = "%d %s-%s".format(
                    DateTimeUtil.getThisYear(),
                    DateTimeUtil.dateToString(dateRange.first, DateTimeUtil.DATE_FORMAT_3),
                    DateTimeUtil.dateToString(dateRange.second, DateTimeUtil.DATE_FORMAT_3)
                )
            }
            Period.YEAR   -> {
                tvType.text = getString(R.string.this_year)
                tvTime.text = "${DateTimeUtil.getThisYear()}"
            }
            Period.DECADE -> {
                tvType.text = getString(R.string.this_decade)
                val yearRange = DateTimeUtil.getYearFromNowWithGap(-10)
                tvTime.text = "%d-%d".format(
                    yearRange.first(),
                    yearRange.last()
                )
            }
        }

        val layoutManager = LinearLayoutManager(context, RecyclerView.VERTICAL, false)
        rvStatistic.layoutManager = layoutManager
        val itemDecoration = DividerItemDecoration(context, RecyclerView.VERTICAL)
        val dividerDrawable =
            ContextCompat.getDrawable(context!!, R.drawable.double_divider_athens_gray)
        if (dividerDrawable != null) itemDecoration.setDrawable(dividerDrawable)
        rvStatistic.addItemDecoration(itemDecoration)
        rvStatistic.adapter = adapter

        // TODO replace with real data
        val json = context?.assets?.open(
            when (period) {
                Period.WEEK   -> "usage_week.json"
                Period.YEAR   -> "usage_year.json"
                Period.DECADE -> "usage_decade.json"
            }
        )?.bufferedReader().use { r -> r?.readText() }
        val gson = Gson().newBuilder().create()
        val sectionRs = gson.fromJson(json, GetStatisticResponse::class.java).sectionRs
        val sectionMV =
            sectionRs.map { s -> SectionModelView.newInstance(s, Random().nextInt(100)) }
        adapter.set(sectionMV)
    }

}