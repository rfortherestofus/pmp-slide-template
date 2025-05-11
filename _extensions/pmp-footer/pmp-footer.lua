return {
  ['pmp-footer'] = function()
 
    local raw = [[<div class="two-col-footer">
      <p><img width="100" src="../../../../../assets/imgs/PMP%20-%20Blue.png"></p>
      <div class="color-bar"></div>
      </div>]]
  
    return pandoc.RawBlock('html', raw)
  end
}
