def generate_white_label_config(partner_name, logo_url, primary_color):
    return {
        "partner": partner_name,
        "branding": {"logo_url": logo_url, "primary_color": primary_color},
        "features": ["predictive_ai", "compliance"]
    }

print(generate_white_label_config("PartnerX", "http://logo.com", "#FF5733"))