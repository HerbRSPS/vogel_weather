A highly advanced weather and time control system for ESX servers.

**✨ Features**

**Core Functionality**

* **Smooth Weather Transitions** - No flickering or sudden changes, proper overtime transitions
* **Database Persistence** - Weather and time state automatically saves and restores on server restart
* **Dynamic Weather System** - Automatic weather changes with configurable intervals (can be toggled)
* **Dynamic Time System** - Realistic time progression with configurable speed (can be frozen)
* **Time Scale Control** - Adjust how fast time moves (1x, 5x, 10x, 30x, 60x speeds)
* **Blackout Mode** - Toggle city-wide blackout for events/roleplay
* **Time Presets** - Quick access to Sunrise, Noon, Sunset, and Midnight

**Dual System Support**

* **Dual UI Systems** - Supports both lation_ui (modern) and ESX menus with automatic fallback
* **Dual Notifications** - lation_ui notifications or ESX.ShowNotification based on preference
* **Dual Permissions** - Choose between ESX admin groups OR license-based whitelist

**Developer Features**

* **Multi-Language Support** - Includes Dutch and English translations, easily expandable
* **Extensive Debug System** - Toggle detailed logging for troubleshooting
* **Open Source** - Fully accessible code for customization

**⚡Performance**

**Optimized for production:** Runs at **0.00-0.01ms** resource usage

**🌦️Controls**

* Weather menu with all GTA weather types (Clear, Rain, Thunder, Snow, Fog, etc.)
* Time control with custom hour/minute input
* Toggle switches for dynamic weather/time
* Admin-only access with configurable permissions

**📋 Requirements**

* **ESX Framework** (Only ESX supported)
* **ox_lib** (v2+)
* **oxmysql**
* **lation_ui** (Optional - falls back to ESX UI if not present)

**🛠️ Installation**

1. Download and extract to your resources folder
2. Add `ensure vogel_weather` to your server.cfg
4. Restart your server

**⚙️ Configuration Highlights**

**📝 Commands**

* `/weather` - Opens the weather & time control menu (admins only)

**📥 Download**

**GitHub:** https://github.com/HerbRSPS/vogel_weather

**📊 Script Information**

* It's about 1,500 lines of code

**🐛 Support & Issues**

If you encounter any bugs or have feature requests, please open an issue on GitHub. I'll do my best to provide support and keep the script updated.

**📜 License**

This script is released as open source. Feel free to modify and use it on your server.
