/**
Copyright (c) 2019 İbrahim Süren

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
package com.bitmark.fbm.util.view.bottomview

import android.content.Context
import android.content.res.XmlResourceParser
import android.graphics.drawable.Drawable
import androidx.core.content.ContextCompat

class BottomBarParser(private val context: Context, res: Int) {

    private val parser: XmlResourceParser = context.resources.getXml(res)

    fun parse(): List<BottomBarItem> {
        val items: MutableList<BottomBarItem> = mutableListOf()
        var eventType: Int?

        do {
            eventType = parser.next()

            if (eventType == XmlResourceParser.START_TAG && parser.name == Constants.ITEM_TAG)
                items.add(getTabConfig(parser))

        } while (eventType != XmlResourceParser.END_DOCUMENT)

        return items.toList()
    }

    private fun getTabConfig(parser: XmlResourceParser): BottomBarItem {
        val attributeCount = parser.attributeCount
        var itemText: String? = null
        var itemDrawable: Drawable? = null

        for (i in 0 until attributeCount)
            when (parser.getAttributeName(i)) {
                Constants.ICON_ATTRIBUTE -> itemDrawable =
                    ContextCompat.getDrawable(context, parser.getAttributeResourceValue(i, 0))
                Constants.TITLE_ATTRIBUTE -> {
                    itemText = try {
                        context.getString(parser.getAttributeResourceValue(i, 0))
                    } catch (e: Exception) {
                        parser.getAttributeValue(i)
                    }
                }
            }

        return BottomBarItem(itemText!!, itemDrawable!!)
    }
}