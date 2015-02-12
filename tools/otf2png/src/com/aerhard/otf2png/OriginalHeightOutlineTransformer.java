package com.aerhard.otf2png;

import java.awt.*;
import java.awt.geom.AffineTransform;

public class OriginalHeightOutlineTransformer implements OutlineTransformer {

    private int padding;
    private Rectangle bounds;

    public OriginalHeightOutlineTransformer(int padding) {
        this.padding = padding;
    }

    @Override
    public Shape transform(Shape outline, Rectangle bounds) {
        this.bounds = bounds;
        AffineTransform at = new AffineTransform();
        at.translate(bounds.x * -1 + padding, bounds.y * -1
                + padding);
        return at.createTransformedShape(outline);
    }

    @Override
    public Dimension getResultDimension() {

        // make sure each dimension is 1px at minimum
        int resultImageHeight = Math.max(1, bounds.height + 2 * padding);
        int resultImageWidth = Math.max(1, bounds.width + 2 * padding);
        return new Dimension(resultImageWidth, resultImageHeight);

    }
}
