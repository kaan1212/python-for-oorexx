def qux():
    return 'quux'


id = 0


def auto_increment():
    global id
    id += 1
    return id
