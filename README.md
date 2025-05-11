

<!-- THIS README IS GENERATED VIA THE QMD-FILE README.QMD. MAKE EDITS THERE. -->

<!-- THIS README IS GENERATED VIA THE QMD-FILE README.QMD. MAKE EDITS THERE. -->

<!-- THIS README IS GENERATED VIA THE QMD-FILE README.QMD. MAKE EDITS THERE. -->

<!-- THIS README IS GENERATED VIA THE QMD-FILE README.QMD. MAKE EDITS THERE. -->

<!-- THIS README IS GENERATED VIA THE QMD-FILE README.QMD. MAKE EDITS THERE. -->

<!-- THIS README IS GENERATED VIA THE QMD-FILE README.QMD. MAKE EDITS THERE. -->

# Portland Means Progress Slide Template

This documentation was last rendered

``` r
Sys.time()
```

    [1] "2025-05-11 10:56:02 CEST"

## Using the `pmp-footer` shortcode

This project uses the extension `pmp-footer`. This extension is just a
very simple one. All it offers is the `` shortcode. This footer will
throw the following raw HTML code:

``` html
<div class="two-col-footer">
    <p>
        <img width="100" src="../../../../../assets/imgs/PMP%20-%20Blue.png">
    </p>
    <div class="color-bar"></div>
</div>
```

So for the shortcode to work properly, you will need two things:

- The style file `theme.scss` that contains the styling for the classes
  `two-col-footer` and `color-bar`.
- The image file `PMP - Blue.png` located in a directory `assets/imgs/`
  (the `../../../../../` part in the `src` path is just a clunky way to
  navigate out of the directories that RevealJS creates.)

> [!IMPORTANT]
>
> This footer works only properly within `<div>`-containers of the class
> `.theme-two-cols`.
