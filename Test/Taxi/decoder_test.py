def decode(i):
    out = []
    out.append(i % 4)
    print(out)
    i = i // 4
    out.append(i % 5)
    print(out)
    i = i // 5
    out.append(i % 5)
    print(out)
    i = i // 5
    out.append(i)
    print(out)
    assert 0 <= i < 5
    return reversed(out)
i = 211
print(decode(i))
print(i)
