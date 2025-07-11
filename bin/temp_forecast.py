#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.13"
# dependencies = [
#      "matplotlib",
#      "requests",
#      "seaborn",
# ]
# ///
import argparse
from datetime import datetime

import matplotlib.pyplot as plt
import requests


def get_weather_data(zip_code):
    """
    Fetches the full 24-hour temperature forecast for a given zip code on the current day.
    """
    try:
        headers = {"User-Agent": "WeatherPlotCLI/1.0 (your-email@example.com)"}
        geocoding_url = f"https://nominatim.openstreetmap.org/search?postalcode={zip_code}&countrycodes=us&format=json"

        geo_response = requests.get(geocoding_url, headers=headers)
        geo_response.raise_for_status()
        location_data = geo_response.json()

        if not location_data:
            print(f"❌ Error: Could not find location for zip code '{zip_code}'.")
            print("Please make sure it's a valid US zip code and try again.")
            return None, None

        result = location_data[0]
        latitude = result["lat"]
        longitude = result["lon"]
        location_name = result.get("display_name", "Unknown Location")
        if "," in location_name:
            location_name = ", ".join(location_name.split(",")[:2])

        today_iso = datetime.now().date().isoformat()
        weather_url = (
            f"https://api.open-meteo.com/v1/forecast?"
            f"latitude={latitude}&longitude={longitude}"
            f"&hourly=temperature_2m&temperature_unit=fahrenheit"
            f"&timezone=auto"
            f"&start_date={today_iso}&end_date={today_iso}"
        )

        weather_response = requests.get(weather_url)
        weather_response.raise_for_status()
        return weather_response.json(), location_name

    except requests.exceptions.RequestException as e:
        print(f"An error occurred while connecting to the network: {e}")
        return None, None


def plot_temperature(weather_data, location_name):
    """
    Plots the hourly temperature forecast as a bar chart with the date in the title.
    """
    hourly_data = weather_data.get("hourly", {})
    times = hourly_data.get("time", [])
    temperatures = hourly_data.get("temperature_2m", [])
    temp_unit = weather_data.get("hourly_units", {}).get("temperature_2m", "°F")

    if not times or not temperatures:
        print(
            "API did not return valid weather data for today. Please try again later."
        )
        return

    datetime_objects = [datetime.fromisoformat(t) for t in times]
    hour_labels = [dt.strftime("%-I %p") for dt in datetime_objects]

    # --- NEW: Get and format the date for the title ---
    # We take the date from the first data point and format it nicely.
    plot_date_str = datetime_objects[0].strftime("%A, %B %d, %Y")

    plt.style.use("seaborn-v0_8-whitegrid")
    plt.figure(figsize=(15, 7))
    bars = plt.bar(hour_labels, temperatures, color="deepskyblue", zorder=2)

    for bar in bars:
        yval = bar.get_height()
        plt.text(
            bar.get_x() + bar.get_width() / 2.0,
            yval + 0.2,
            f"{yval:.0f}{temp_unit}",
            va="bottom",
            ha="center",
            fontsize=9,
        )

    plt.xlabel("Time of Day", fontsize=12)
    plt.ylabel(f"Temperature ({temp_unit})", fontsize=12)

    # --- MODIFIED: The title now includes the date on a new line ---
    plt.title(
        f"Hourly Temperature Forecast for {location_name}\n{plot_date_str}",
        fontsize=16,
    )

    plt.ylim(top=max(temperatures) + 5)
    plt.grid(axis="y", linestyle="--", alpha=0.7, zorder=1)
    plt.tight_layout()
    plt.show()


def main():
    """
    Main function to parse arguments and run the program.
    """
    parser = argparse.ArgumentParser(
        description="📊 Plot the full day's hourly temperature forecast for a given US zip code."
    )
    parser.add_argument(
        "zip_code", type=str, help="The US zip code to get the weather forecast for."
    )
    args = parser.parse_args()

    weather_data, location_name = get_weather_data(args.zip_code)
    if weather_data and location_name:
        plot_temperature(weather_data, location_name)


if __name__ == "__main__":
    main()
