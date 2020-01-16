/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */
package com.bitmark.fbm.feature.increaseprivacy

import android.text.Html
import android.widget.TextView
import androidx.lifecycle.Observer
import com.bitmark.fbm.R
import com.bitmark.fbm.feature.BaseAppCompatActivity
import com.bitmark.fbm.feature.BaseViewModel
import com.bitmark.fbm.feature.Navigator
import com.bitmark.fbm.feature.Navigator.Companion.RIGHT_LEFT
import com.bitmark.fbm.logging.EventLogger
import com.bitmark.fbm.util.ext.logSharedPrefError
import com.bitmark.fbm.util.ext.setSafetyOnclickListener
import com.bitmark.fbm.util.view.WebViewActivity
import kotlinx.android.synthetic.main.activity_increase_privacy.*
import javax.inject.Inject


class IncreasePrivacyActivity : BaseAppCompatActivity() {

    companion object {
        private const val TURN_OF_FACE_REG_URL = "https://m.facebook.com/privacy/touch/facerec/"
        private const val DELETE_EMAIL_URL = "https://www.facebook.com/mobile/facebook/contacts/"
        private const val DELETE_PHONE_URL = "https://www.facebook.com/mobile/messenger/contacts/"
        private const val OPT_OUT_ADS_DATA_URL =
            "https://m.facebook.com/control_center/checkup/third_party/?entry_product=account_settings_menu"
        private const val OPT_OUT_ADS_ACTIVITY_URL = "https://m.facebook.com/ads/settings/fpd/"
        private const val OPT_OUT_FRIEND_URL = "https://m.facebook.com/settings/ads/socialcontext/"
    }

    @Inject
    internal lateinit var viewModel: IncreasePrivacyViewModel

    @Inject
    internal lateinit var navigator: Navigator

    @Inject
    internal lateinit var logger: EventLogger

    private lateinit var tvUrlPairList: List<Pair<TextView, String>>

    override fun layoutRes(): Int = R.layout.activity_increase_privacy

    override fun viewModel(): BaseViewModel? = viewModel

    override fun initComponents() {
        super.initComponents()

        tvTurnOffFaceReg.text = Html.fromHtml(getString(R.string.turn_off_face_reg_arrow))
        tvTurnOffFaceRegMsg.text = Html.fromHtml(getString(R.string.tap_the_option_and_select_no))
        tvDeleteAllEmail.text = Html.fromHtml(getString(R.string.delete_all_your_email_arrow))
        tvDeleteAllEmailMsg.text = Html.fromHtml(getString(R.string.tap_delete_all))
        tvDeleteAllPhone.text = Html.fromHtml(getString(R.string.delete_all_your_phone_arrow))
        tvDeleteAllPhoneMsg.text = Html.fromHtml(getString(R.string.tap_delete_all_contacts))
        tvOptOutOfAdsData.text = Html.fromHtml(getString(R.string.opt_out_of_ads_data_arrow))
        tvOptOutOfAdsDataMsg.text = Html.fromHtml(getString(R.string.tap_continue_change_to))
        tvOptOutOfAdsActivity.text =
            Html.fromHtml(getString(R.string.opt_out_of_ads_activity_arrow))
        tvOptOutOfAdsActivityMsg.text = Html.fromHtml(getString(R.string.select_no))
        tvOptOutOfFriend.text = Html.fromHtml(getString(R.string.opt_out_of_friend_arrow))
        tvOptOutOfFriendMsg.text = Html.fromHtml(getString(R.string.select_no_one))

        tvUrlPairList = listOf(
            Pair(tvTurnOffFaceReg, TURN_OF_FACE_REG_URL),
            Pair(tvDeleteAllEmail, DELETE_EMAIL_URL),
            Pair(tvDeleteAllPhone, DELETE_PHONE_URL),
            Pair(tvOptOutOfAdsData, OPT_OUT_ADS_DATA_URL),
            Pair(tvOptOutOfAdsActivity, OPT_OUT_ADS_ACTIVITY_URL),
            Pair(tvOptOutOfFriend, OPT_OUT_FRIEND_URL)
        )

        tvUrlPairList.forEach { p ->
            p.first.setSafetyOnclickListener {
                viewModel.saveLinkClicked(p.second)
                val bundle = WebViewActivity.getBundle(
                    p.second,
                    getString(R.string.increase_privacy)
                )
                navigator.anim(RIGHT_LEFT).startActivity(WebViewActivity::class.java, bundle)
            }
        }

        ivBack.setSafetyOnclickListener {
            navigator.anim(RIGHT_LEFT).finishActivity()
        }
    }

    override fun observe() {
        super.observe()

        viewModel.listLinkClickedLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isSuccess() -> {
                    val links = res.data()!!
                    tvUrlPairList.forEach { p ->
                        p.first.setTextColor(
                            getColorStateList(
                                if (links.contains(p.second)) {
                                    R.color.color_yukon_gold_stateful
                                } else {
                                    R.color.color_black_stateful
                                }
                            )
                        )
                    }

                }

                res.isError() -> {
                    logger.logSharedPrefError(res.throwable(), "list link clicked error")
                }
            }
        })

        viewModel.saveLinkClickedLiveData.asLiveData().observe(this, Observer { res ->
            when {
                res.isError() -> {
                    logger.logSharedPrefError(res.throwable(), "save link clicked error")
                }
            }
        })

    }

    override fun onResume() {
        super.onResume()

        viewModel.listLinkClicked()
    }

    override fun onBackPressed() {
        navigator.anim(RIGHT_LEFT).finishActivity()
        super.onBackPressed()
    }
}