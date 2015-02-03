package com.aerhard.otf2png;

import java.awt.*;
import java.awt.geom.AffineTransform;

public class FitToHeightOutlineTransformer implements OutlineTransformer {

    private int width;
    private int height;
    private int padding;

    public FitToHeightOutlineTransformer(int width, int height, int padding) {
        this.padding = padding;
        this.width = width;
        this.height = height;
    }

    @Override
    public Shape transform(Shape outline, Rectangle bounds) {

        float glyphWidth = width - (2 * padding);
        float glyphHeight = height - (2 * padding);
        float scaleFactor = Math.min(glyphWidth / bounds.width, glyphHeight
                / bounds.height);

        int centerX = width / 2;
        int centerY = height / 2;

        float scaledOffsetX = (bounds.x + (bounds.width / 2)) * scaleFactor;
        float scaledOffsetY = (bounds.y + (bounds.height / 2)) * scaleFactor;

        AffineTransform at = new AffineTransform();
        at.translate(centerX - scaledOffsetX, centerY - scaledOffsetY);
        at.scale(scaleFactor, scaleFactor);

        return at.createTransformedShape(outline);
    }

    @Override
    public Dimension getResultDimension() {
        return new Dimension(width, height);
    }

}
