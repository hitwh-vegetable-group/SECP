<?php
    // Check if we have the stuff
    $bHasEmail =                    isset($_POST["email"]);
    $bHasPsw =                      isset($_POST["psw"]);

    // Variables
    $arrMsg =                       array();

    $strEmail =                     "";
    $strPsw =                       "";

    $callback =                     $_GET['callback'];
    
    // Check the stuff
    if(!$bHasEmail || !$bHasPsw)
    {
        $arrMsg = array(
            "code" => 400,
            "msg" => "用户登录信息格式错误，请检查是否没有填写用户名或者密码！",
        );
    }
    else
    {
        $strEmail = $_POST["email"];
        $strPsw = $_POST["psw"];
    }

    if($strEmail == "admin" && $strPsw == "ad")
    {
        $arrMsg = array(
            "code" => 200,
            "msg" => "亲爱的管理员，欢迎回来！",
        );
    }
    else
    {
        $arrMsg = array(
            "code" => 400,
            "msg" => "你正在尝试登陆管理员账户，但是输入了错误的密码！",
        );
    }

    echo $callback.'('.json_encode($arrMsg).')';
?>