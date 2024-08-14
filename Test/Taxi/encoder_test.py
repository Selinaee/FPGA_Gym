def encode(taxi_row, taxi_col, pass_loc, dest_idx):
    # (5) 5, 5, 4
    i = taxi_row
    i *= 5
    i += taxi_col
    i *= 5
    i += pass_loc
    i *= 4
    i += dest_idx
    return i

i = encode (1, 0, 2, 3)
print(i)