/**
 * SPDX-License-Identifier: ISC
 * Copyright © 2014-2020 Bitmark. All rights reserved.
 * Use of this source code is governed by an ISC
 * license that can be found in the LICENSE file.
 */

package com.bitmark.fbm.util.view;

import android.graphics.Canvas;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.view.View;

import androidx.recyclerview.widget.RecyclerView;

import org.jetbrains.annotations.NotNull;

public class TopVerticalItemDecorator extends RecyclerView.ItemDecoration {

    private Drawable mDivider;

    public TopVerticalItemDecorator(Drawable divider) {
        mDivider = divider;
    }

    @Override
    public void onDraw(@NotNull Canvas c, RecyclerView parent, @NotNull RecyclerView.State state) {
        int left = 0;
        int right = parent.getWidth();

        int childCount = parent.getChildCount();
        for (int i = 0; i < childCount; i++) {
            View child = parent.getChildAt(i);
            int position = parent.getChildLayoutPosition(child);

            int bottom = child.getTop();
            int top = bottom - mDivider.getIntrinsicHeight();

            mDivider.setBounds(left, top, right, bottom);
            mDivider.draw(c);

            if (position == childCount - 1) {
                Rect bounds = new Rect();
                parent.getDecoratedBoundsWithMargins(child, bounds);
                bottom = bounds.bottom + Math.round(child.getTranslationY());
                top = bottom - mDivider.getIntrinsicHeight();
                mDivider.setBounds(left, top, right, bottom);
                mDivider.draw(c);
            }
        }
    }

    @Override
    public void getItemOffsets(Rect outRect, @NotNull View view, RecyclerView parent, @NotNull RecyclerView.State state) {
        int height = mDivider.getIntrinsicHeight();
        int position = parent.getChildLayoutPosition(view);

        outRect.top = (position == 0) ? height : 0;
        outRect.bottom = height;
    }
}
