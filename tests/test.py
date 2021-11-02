from collections import namedtuple, OrderedDict
import requests

#r = requests.get("http://127.0.0.1:8080/test/authors")
#data = r.json()
#print(data)
#print(data["rows"][0])
#print(data["rows"][0]["id"])

TestResult = namedtuple("TestResult", ["success", "data"])
Test = namedtuple("Test", ["category", "name", "function",])

tests = []
results = OrderedDict()
succeeded = 0
failed = 0

def define_tests():
    add_test("inserts", "basic insert 1", test_insert1)
    add_test("inserts", "basic insert 2", test_insert2)
    add_test("inserts", "basic insert 3", test_insert3)
    add_test("queries", "query all authors", test_query_all)
    add_test("queries", "query one author", test_query_one)
    add_test("queries", "query range authors", test_query_range)
    add_test("deletes", "basic delete 1", test_delete1)
    add_test("deletes", "basic delete 2", test_delete2)
    add_test("deletes", "basic delete 3", test_delete3)

def add_test(category, name, function):
    global tests
    tests.append(Test(category, name, function))

def run_tests():
    global tests, results
    global succeeded, failed
    totalnum = len(tests)

    print("--- Running Tests --- ")

    for index, test in enumerate(tests):
        print("Running test '{}' from category '{}' ({} of {}):".format(test.name, test.category, index + 1, totalnum), end = " ")
        res = test.function()
        results[test.category + ":" + test.name] = res

        if(res.success == True):
            print("Success")
            succeeded += 1
        else:
            print("Failed")
            failed += 1

def print_summary():
    global tests
    global results
    global succeeded, failed

    print("")
    print("--- Summary ---")

    for key, val in results.items():
        rstr = "SUCCESS" if val.success else "FAIL"
        print(key + ": " + rstr)
        print(val.data)
        print("")

    print("---")
    print("{} of {} tests succeeded, {} failed.".format(succeeded, len(tests), failed))

def test_insert1():
    payload = '{"type":"author","name":"Emil","year":1968}'
    r = requests.put("http://127.0.0.1:8080/testsuite/authors", data = payload)
    return(create_result(r.json()))

def test_insert2():
    payload = '{"type":"author","name":"Egon","year":1974}'
    r = requests.put("http://127.0.0.1:8080/testsuite/authors", data = payload)
    return(create_result(r.json()))

def test_insert3():
    payload = '{"type":"author","name":"Hugo","year":1980}'
    r = requests.put("http://127.0.0.1:8080/testsuite/authors", data = payload)
    return(create_result(r.json()))

def test_query_all():
    r = requests.get("http://127.0.0.1:8080/testsuite/authors")
    rjson = r.json()

    if rjson["total_rows"] == 3:
        if rjson["rows"][0]["key"] == "Egon" \
            and rjson["rows"][1]["key"] == "Emil" \
            and rjson["rows"][2]["key"] == "Hugo":
            return(TestResult(True, rjson))
        else:
            return(TestResult(False, rjson))
    else:
        return(TestResult(False, rjson))

def test_query_one():
    r = requests.get("http://127.0.0.1:8080/testsuite/authors?key=\"Hugo\"")
    rjson = r.json()

    if rjson["total_rows"] == 3 and rjson["offset"] == 2:
        if rjson["rows"][0]["key"] == "Hugo":
            return(TestResult(True, rjson))
        else:
            return(TestResult(False, rjson))
    else:
        return(TestResult(False, rjson))

def test_query_range():
    r = requests.get("http://127.0.0.1:8080/testsuite/authors?startkey=\"Egon\"&endkey=\"Emil\"")
    rjson = r.json()

    if rjson["total_rows"] == 3:
        if rjson["rows"][0]["key"] == "Egon" \
            and rjson["rows"][1]["key"] == "Emil":
            return(TestResult(True, rjson))
        else:
            return(TestResult(False, rjson))
    else:
        return(TestResult(False, rjson))

def test_delete1():
    global results
    data = results["inserts:basic insert 1"].data
    r = requests.delete("http://127.0.0.1:8080/testsuite/authors/" + data["id"] + "?rev=" + data["rev"])
    return(create_result(r.json()))

def test_delete2():
    global results
    data = results["inserts:basic insert 2"].data
    r = requests.delete("http://127.0.0.1:8080/testsuite/authors/" + data["id"] + "?rev=" + data["rev"])
    return(create_result(r.json()))

def test_delete3():
    global results
    data = results["inserts:basic insert 3"].data
    r = requests.delete("http://127.0.0.1:8080/testsuite/authors/" + data["id"] + "?rev=" + data["rev"])
    return(create_result(r.json()))


def create_result(rjson):
    if rjson["ok"] == True:
        return(TestResult(True, rjson))
    else:
        return(TestResult(False, rjson))


define_tests()
run_tests()
print_summary()