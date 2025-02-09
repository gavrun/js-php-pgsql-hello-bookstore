<?php
//config error processing and reporting
error_reporting(E_ALL);
ini_set('display_errors', true);
set_error_handler(
    function ($errlevel, $errmessage, $errfile, $errline, $errcontext = null, $trace = null) {
        if ($errlevel & error_reporting()) {
            throw new ErrorException($errmessage, E_USER_ERROR, 1, $errfile, $errline);
        } else {
            return;
        }
    }
);

session_start();
require 'config.php';
require 'Pg.php';
require 'PgException.php';
require 'PgCheckObject.php';

$action = $_GET['action'];
$params = $_POST ?? [];
$pg = new Pg();

try {
    $isSystemAction = in_array($action, ['getRoles', 'setRole']);
    $pg->connect($isSystemAction ? 'ag' : ($_SESSION['role'] ?? 'ag')); //$pg->connect($isSystemAction ? 'postgres' : ($_SESSION['role'] ?? 'postgres'));

    $check = PgCheckObject::create($pg, $action);
    $objectInfo = $check->checkObject();
    switch ($action) {
        case 'getRoles':
            $data = array_map(
                function ($r) {
                    return $r->usename;
                },
                $pg->query("select usename from pg_user order by 1", [], false)->rows
            );
            break;
        case 'setRole':
            $_SESSION['role'] = $params['role'];
            break;
        case 'getAuthors':
            $data = $pg->query("select * from authors_v", []);
            break;
        case 'addAuthor':
            $data = $pg->execFunction("add_author", $_POST);
            break;
        case 'getBooks':
            $data = $pg->query("select * from catalog_v", []);
            break;
        case 'getOperations':
            $data = $pg->query("select * from operations_v where book_id = $1", [$params['book_id']]);
            break;
        case 'addBook':
            $data = $pg->execFunction(
                "add_book",
                [
                    'title' => $_POST['title'],
                    'authors' => '{' . implode(',', $_POST['authors']) . '}'
                ]
            );
            break;
        case 'orderBook':
            $data = $pg->query("update catalog_v set onhand_qty = onhand_qty + $1 where book_id = $2", [$_POST['qty'], $_POST['id']]);
            break;
        case 'findBooks':
            $_POST['author_name'] = trim($_POST['author_name']) === '' ? null : $_POST['author_name'];
            $_POST['book_title'] = trim($_POST['book_title']) === '' ? null : $_POST['book_title'];
            $_POST['in_stock'] = array_key_exists('in_stock', $_POST);
            $data = $pg->query("select * from get_catalog ($1, $2, $3)", array_values($_POST));
            break;
        case 'buyBook':
            $data = $pg->execFunction("buy_book", $_POST);
            break;
        default:
            throw new RuntimeException('Internal error. Unknown server action: ' . $action);
    }
    $columnInfo = $isSystemAction ? '' : $check->checkColumn($data ?? null);
} catch (Exception $e) {
    $err = new stdClass();
    $err->code = $e->getCode();
    $err->message = $e->getMessage();
    $columnInfo = '';
} finally {
    $info = array_values(array_filter([$objectInfo, $columnInfo]));
    $pg->close();
}

header('content-type:application/json');

echo json_encode([
    'data' => $data ?? null,
    'sql' => $pg->sql,
    'err' => $err ?? null,
    'notice' => $pg->notice ?? null,
    'info' => $info
]);
