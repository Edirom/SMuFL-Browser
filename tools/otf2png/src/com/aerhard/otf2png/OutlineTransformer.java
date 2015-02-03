package com.aerhard.otf2png;

import java.awt.*;

public interface OutlineTransformer {

    Shape transform(Shape outline, Rectangle bounds);

    Dimension getResultDimension();

}
