def user_side_formula(capital, tier):
    if tier == "Admin":
        return capital * 3
    return capital * 1.5

print(user_side_formula(10000, "Admin"))  # Output: 30000