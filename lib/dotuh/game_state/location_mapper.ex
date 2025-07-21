defmodule Dotuh.GameState.LocationMapper do
  @moduledoc """
  Maps Dota 2 coordinates to meaningful location names for coaching purposes.

  The Dota 2 map coordinate system typically ranges from approximately:
  - X: -8000 to +8000 
  - Y: -8000 to +8000

  With Radiant base in the bottom-left and Dire base in the top-right.
  """

  @doc """
  Converts x,y coordinates to a location name.
  Returns a string describing the general area of the map.
  """
  def coordinates_to_location(xpos, ypos) when is_number(xpos) and is_number(ypos) do
    cond do
      # Bases
      in_radiant_base?(xpos, ypos) -> "radiant_base"
      in_dire_base?(xpos, ypos) -> "dire_base"
      # River and central areas
      in_river?(xpos, ypos) -> "river"
      in_roshan_pit?(xpos, ypos) -> "roshan_pit"
      # Lanes
      in_top_lane?(xpos, ypos) -> "top_lane"
      in_mid_lane?(xpos, ypos) -> "mid_lane"
      in_bot_lane?(xpos, ypos) -> "bot_lane"
      # Jungles
      in_radiant_jungle?(xpos, ypos) -> "radiant_jungle"
      in_dire_jungle?(xpos, ypos) -> "dire_jungle"
      # Side shops and other areas
      in_radiant_side?(xpos, ypos) -> "radiant_side"
      in_dire_side?(xpos, ypos) -> "dire_side"
      # Default for unknown areas
      true -> "unknown_area"
    end
  end

  def coordinates_to_location(_, _), do: "invalid_coordinates"

  # Base areas - corners of the map
  defp in_radiant_base?(x, y), do: x < -5000 and y < -5000
  defp in_dire_base?(x, y), do: x > 5000 and y > 5000

  # River - diagonal band through the middle
  defp in_river?(x, y) do
    # River roughly follows the diagonal from bottom-right to top-left
    # Using a band around the y = -x line with some tolerance
    distance_from_diagonal = abs(x + y)
    distance_from_diagonal < 1500 and not in_roshan_pit?(x, y)
  end

  # Roshan pit - specific area in the river
  defp in_roshan_pit?(x, y) do
    # Roshan pit is typically around coordinates (-2000, 1500) to (-1000, 2500)
    x >= -2500 and x <= -500 and y >= 1000 and y <= 3000
  end

  # Lanes - main pathways
  defp in_top_lane?(x, y) do
    # Top lane runs roughly from (-6000, 6000) to (6000, 6000)
    y > 4000 and y < 7000 and not in_dire_base?(x, y)
  end

  defp in_bot_lane?(x, y) do
    # Bot lane runs roughly from (-6000, -6000) to (6000, -6000)  
    y < -4000 and y > -7000 and not in_radiant_base?(x, y)
  end

  defp in_mid_lane?(x, y) do
    # Mid lane runs diagonally, close to but not in river
    distance_from_diagonal = abs(x + y)
    distance_from_diagonal >= 1500 and distance_from_diagonal <= 3000
  end

  # Jungle areas
  defp in_radiant_jungle?(x, y) do
    # Radiant jungle: bottom-right area
    x > 1000 and y < -1000 and not in_bot_lane?(x, y) and not in_radiant_base?(x, y)
  end

  defp in_dire_jungle?(x, y) do
    # Dire jungle: top-left area  
    x < -1000 and y > 1000 and not in_top_lane?(x, y) and not in_dire_base?(x, y)
  end

  # General side areas
  defp in_radiant_side?(x, y) do
    # Radiant side: bottom-left quadrant (excluding base and jungle)
    x < 0 and y < 0 and not in_radiant_base?(x, y) and not in_dire_jungle?(x, y) and
      not in_river?(x, y) and not in_bot_lane?(x, y) and not in_mid_lane?(x, y)
  end

  defp in_dire_side?(x, y) do
    # Dire side: top-right quadrant (excluding base and jungle)
    x > 0 and y > 0 and not in_dire_base?(x, y) and not in_radiant_jungle?(x, y) and
      not in_river?(x, y) and not in_top_lane?(x, y) and not in_mid_lane?(x, y)
  end

  @doc """
  Gets a human-readable description of a location.
  """
  def location_description(location) do
    case location do
      "radiant_base" -> "Radiant Base"
      "dire_base" -> "Dire Base"
      "river" -> "River"
      "roshan_pit" -> "Roshan Pit"
      "top_lane" -> "Top Lane"
      "mid_lane" -> "Mid Lane"
      "bot_lane" -> "Bot Lane"
      "radiant_jungle" -> "Radiant Jungle"
      "dire_jungle" -> "Dire Jungle"
      "radiant_side" -> "Radiant Side"
      "dire_side" -> "Dire Side"
      "unknown_area" -> "Unknown Area"
      "invalid_coordinates" -> "Invalid Location"
      _ -> location
    end
  end

  @doc """
  Determines if a location change is significant enough to alert about.
  """
  def significant_location_change?(from_location, to_location) do
    # Don't alert if location hasn't actually changed
    if from_location == to_location do
      false
    else
      # Alert for these types of movements
      case {from_location, to_location} do
        # Enemy entering dangerous areas (but not if already there)
        {from, "roshan_pit"} when from != "roshan_pit" ->
          true

        {from, location} when location in ["radiant_base", "dire_base"] and from != location ->
          true

        # Lane changes
        {from, to}
        when from in ["top_lane", "mid_lane", "bot_lane"] and
               to in ["top_lane", "mid_lane", "bot_lane"] and from != to ->
          true

        # Jungle to lane movements
        {from, to}
        when from in ["radiant_jungle", "dire_jungle"] and
               to in ["top_lane", "mid_lane", "bot_lane"] ->
          true

        # River movements (potential ganks) - but not if already in river
        {from, "river"} when from != "river" ->
          true

        # Different sides of map
        {"radiant_side", location} when location in ["dire_side", "dire_jungle"] ->
          true

        {"dire_side", location} when location in ["radiant_side", "radiant_jungle"] ->
          true

        # Any movement from unknown areas
        {"unknown_area", _} ->
          true

        _ ->
          false
      end
    end
  end
end
