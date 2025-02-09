<?php
class Pg
{
    public $sql = [];
    private $connection = null;

    /** create database connection
     */
    public function connect($role='ag') //($role='postgres') ($role='ag')
    {
        $connectParams = DATA_SOURCE;
        $connectParams['user'] = $role;
        $connectParams['password'] = '0000'; //$role; //assume password to be the same as user name
        $connectString = implode(
            ' ',
            array_map(
                function ($key, $value) {
                    return $key . '=\'' . addslashes($value) . '\'';
                },
                array_keys($connectParams),
                $connectParams
            )
        );
        $this->connection = pg_connect($connectString);
    }
    /** close database connection
     */
    public function close()
    {
        if ($this->connection) {
            pg_close($this->connection);
        }
    }

    /** SQL select
     * @param sql
     * @param params - integer-indexed array of values for parameters
     * @return function value
     */
    public function query($sql, $params = [], $displaySql = true)
    {
        if ($displaySql) {
            $this->sql[] = $sql;
        }
        pg_send_query_params(
            $this->connection,
            $sql,
            array_map(
                function ($v) {
                    switch (gettype($v)) {
                        case 'boolean':
                            return $v ? 'true' : 'false';
                        default:
                            return $v;
                    }
                },
                $params
            )
        );
        $result = pg_get_result($this->connection);
        if ($notice = pg_last_notice($this->connection)) {
            $this->notice = $notice;
        }
        if (pg_result_error($result) === '') {
            $cols = array_map(
                function ($r) use ($result) {
                    return pg_field_name($result, $r);
                },
                pg_num_fields($result) ? range(0, pg_num_fields($result) - 1) : []
            );
            $rows = pg_fetch_all($result);
            if (pg_num_rows($result) === 0) {
                $rows = [];
            } else {
                $rows = array_map(function ($r) {
                    return (object)$r;
                }, (array)$rows);
            }
            pg_free_result($result);
            return (object)['columns' => $cols, 'rows' => $rows];
        } else {
            $error = (object)[];
            foreach (
                [
                    'severity' => PGSQL_DIAG_SEVERITY,
                    'code' => PGSQL_DIAG_SQLSTATE,
                    'message' => PGSQL_DIAG_MESSAGE_PRIMARY,
                    'detail' => PGSQL_DIAG_MESSAGE_DETAIL,
                    'hint' => PGSQL_DIAG_MESSAGE_HINT,
                    'position' => PGSQL_DIAG_STATEMENT_POSITION
                ]
                as $fld => $num
            ) {
                $error->{$fld} = pg_result_error_field($result, $num);
            }
            pg_free_result($result);
            throw new PgException($error);
        }
    }
    /** execute stored function
     * @param name
     * @param params - associative array of values for function parameters
     * @return function value
     */
    public function execFunction($name, $params = [])
    {
        $sql =
            'select ' . $name . ' (' .
            (
                count($params) ?
                PHP_EOL . chr(9) .
                implode(',' . PHP_EOL . chr(9), array_map(function ($parName, $parNum) {
                    return $parName . '=>$' . ($parNum + 1);
                }, array_keys($params), array_keys(array_keys($params)))) .
                PHP_EOL
                : ''
            ) .
            ') result';
        return $this->query($sql, array_values($params), true)->rows;
    }
}
