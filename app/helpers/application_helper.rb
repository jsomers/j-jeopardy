# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  $P1_score = 0
  def time(len)
    spice = rand(50) / 100.0
    base = 0.29 * len + 1.2
    if len <= 4 then base += 1.5 end
    t = base + spice
    return [1 + t.to_i, ((t - t.to_i) * 10).to_i]
  end
end
