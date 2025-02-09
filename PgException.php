<?php
class PgException extends RuntimeException
{
    function __construct($props)
    {
        foreach ($props as $prop => $value) {
            $this->{$prop} = $value;
        }
    }
}
