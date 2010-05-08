!SLIDE
# Wrapping it in an (im)pratical (hypothetical) example

!SLIDE center
# Twube

Asking the twitterverse for London travel directions

!SLIDE
# Twube

<blockquote style="font-family:17pt;font-family:Times;font-style:italic">
Anyone know how I get from Charing Cross to Kentish Town #twube
</blockquote>

!SLIDE
# Twube

<blockquote style="font-family:17pt;font-family:Times;font-style:italic">
Anyone know how I get from <span style="color:#cc0000">Charing Cross</span> to <span style="color:#cc0000">Kentish Town</span> #twube
</blockquote>

!SLIDE
# Twube

    if text.match(/#/) && matched = text.match(/from (.*) to (.*) #/)
      from, to = [*matched][-2..-1]
      Twube.plan(from, to)
    end

!SLIDE
# Twube
    
    [{:departs=>"15:21",
      :steps=>
       ["Charing Cross Underground Station",
        "Camden Town Underground Station",
        "Kentish Town Underground Station"],
      :arrives=>"15:38",
      :duration=>"00:17"},
    ...