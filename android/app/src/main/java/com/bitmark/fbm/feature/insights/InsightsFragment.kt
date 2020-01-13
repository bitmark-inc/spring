/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2019 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.insights

import android.os.Handler
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import androidx.recyclerview.widget.SimpleItemAnimator
import com.bitmark.fbm.R
import com.bitmark.fbm.data.ext.isServiceUnsupportedError
import com.bitmark.fbm.feature.BaseSupportFragment
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.DialogController
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.account.AccountActivity
import com.bitmark.fbm.logging.Event
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.logging.Tracer
import com.bitmark.fbm.util.ext.scrollToTop
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.view.TopVerticalItemDecorator
import kotlinx.android.synthetic.main.fragment_insights.*
import javax.inject.Inject


class InsightsFragment : BaseSupportFragment() {

    companion object {

        private const val TAG = "InsightsFragment"

        fun newInstance() = InsightsFragment()
    }

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var viewModel: InsightsViewModel

    @Inject
    internal lateinit var logger: EventLogger

    @Inject
    internal lateinit var dialogController: DialogController

    private lateinit var adapter: InsightsRecyclerViewAdapter

    private val handler = Handler()

    override fun layoutRes(): Int = R.layout.fragment_insights

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

        adapter = InsightsRecyclerViewAdapter()
        val layoutManager = LinearLayoutManager(context, RecyclerView.VERTICAL, false)
        rvInsights.layoutManager = layoutManager
        val dividerDrawable = context!!.getDrawable(R.drawable.double_divider_white_black_stroke)
        val itemDecoration = TopVerticalItemDecorator(dividerDrawable)
        rvInsights.addItemDecoration(itemDecoration)
        (rvInsights.itemAnimator as? SimpleItemAnimator)?.supportsChangeAnimations = false
        rvInsights.isNestedScrollingEnabled = false
        rvInsights.adapter = adapter

        adapter.setItemClickListener(object : InsightsRecyclerViewAdapter.ItemClickListener {
            override fun onIncomeInfoClicked() {
                // TODO implement later
            }

        })

        ivAccount.setSafetyOnclickListener {
            navigator.anim(Navigator.RIGHT_LEFT).startActivity(AccountActivity::class.java)
        }
    }

    override fun deinitComponents() {
        handler.removeCallbacksAndMessages(null)
        super.deinitComponents()
    }

    override fun observe() {
        super.observe()

        viewModel.listInsightLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val data = res.data() ?: return@Observer
                    adapter.set(data)
                }

                res.isError() -> {
                    Tracer.ERROR.log(TAG, res.throwable()?.message ?: "unknown")
                    logger.logError(
                        Event.INSIGHTS_LOADING_ERROR,
                        res.throwable()?.message ?: "unknown"
                    )
                    if (!res.throwable()!!.isServiceUnsupportedError()) {
                        adapter.clear()
                        dialogController.alert(
                            R.string.error,
                            R.string.there_was_error_when_loading_insights
                        )
                    }
                }

                res.isLoading() -> {
                }

            }
        })
    }

    override fun onResume() {
        super.onResume()

        if (!adapter.isEmpty()) return
        handler.postDelayed({ viewModel.listInsight() }, 200)
    }

    override fun refresh() {
        super.refresh()
        sv.scrollToTop()
    }

}