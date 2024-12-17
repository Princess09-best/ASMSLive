<?php
session_start();
// Enable full error reporting
error_reporting(E_ALL);

// Display errors on the screen
ini_set('display_errors', '1');
include('includes/dbconnect.php');

if(isset($_POST['login'])) 
  {
    $username=$_POST['username'];
    $password=md5($_POST['password']);
    $sql ="SELECT ID FROM tbluser WHERE UserName=:username and Password=:password";
    $query=$db->prepare($sql);
    $query-> bindParam(':username', $username, PDO::PARAM_STR);
$query-> bindParam(':password', $password, PDO::PARAM_STR);
    $query-> execute();
    $results=$query->fetchAll(PDO::FETCH_OBJ);
    if($query->rowCount() > 0)
{
foreach ($results as $result) {
$_SESSION['uid']=$result->ID;
}


$_SESSION['login']=$_POST['username'];
echo "<script type='text/javascript'> document.location ='dashboard.php'; </script>";
} else{
echo "<script>alert('Invalid Details');</script>";
}
}

?>
<!DOCTYPE html>
<html lang="en">
<head>
  
  <title>ASMS||Login</title>
  <!-- loader-->
  <link href="../assets/css/pace.min.css" rel="stylesheet"/>
  <script src="../assets/js/pace.min.js"></script>
  <!--favicon-->
  <link rel="icon" href="../assets/images/favicon.ico" type="image/x-icon">
  <!-- Bootstrap core CSS-->
  <link href="../assets/css/bootstrap.min.css" rel="stylesheet"/>
  <!-- animate CSS-->
  <link href="../assets/css/animate.css" rel="stylesheet" type="text/css"/>
  <!-- Icons CSS-->
  <link href="../assets/css/icons.css" rel="stylesheet" type="text/css"/>
  <!-- Custom Style-->
  <link href="../assets/css/app-style.css" rel="stylesheet"/>
  
</head>

<body class="bg-theme">

<!-- start loader -->
   <div id="pageloader-overlay" class="visible incoming"><div class="loader-wrapper-outer"><div class="loader-wrapper-inner" ><div class="loader"></div></div></div></div>
   <!-- end loader -->

<!-- Start wrapper-->
 <div id="wrapper">

 <div class="loader-wrapper"><div class="lds-ring">
	<div class="card card-authentication1 mx-auto my-5">
		<div class="card-body">
		 <div class="card-content p-2">
		 	<div class="text-center">
<a href='../index.php'>Ashesi Scholarship Management System</a>
		 	</div>
		  <div class="card-title text-uppercase text-center py-3">Sign In</div>
		    <form method="post" onsubmit="return validateForm()" name="signInForm">
			  <div class="form-group">
			  <label for="exampleInputUsername" class="sr-only">Username</label>
			   <div class="position-relative has-icon-right">
				 
				  <input type="text" class="form-control input-shadow" placeholder="enter your username" required="true" name="username" value="" >
				  <div class="form-control-position">
					  <i class="icon-user"></i>
				  </div>
			   </div>
			  </div>
			  <div class="form-group">
			  <label for="exampleInputPassword" class="sr-only">Password</label>
			   <div class="position-relative has-icon-right">
				  
				  <input type="password" class="form-control input-shadow" placeholder="enter your password" name="password" required="true" value="">
				  <div class="form-control-position">
					  <i class="icon-lock"></i>
				  </div>
			   </div>
			  </div>

			 <div class="form-group col-6">
			  <a href="forgot-password.php">Reset Password</a>
			 </div>
			</div>
			 <button type="submit" class="btn btn-light btn-block" name="login">Sign In</button>
			
			 
			 
			 </form>
		   </div>
		  </div>
		   <div class="card-footer text-center py-3">
		    <p>Not Registered Yet? <a href="register.php"> Sign Up here</a></p>
		    <hr />
		    <a href="../index.php">Home Page</a>
		  </div>
		   
	     </div>
   
  <?php include_once('includes/color-switcher.php');?>
 
	
	</div><!--wrapper-->
	
  <!-- Bootstrap core JavaScript-->
  <script src="../assets/js/jquery.min.js"></script>
  <script src="../assets/js/popper.min.js"></script>
  <script src="../assets/js/bootstrap.min.js"></script>
	
  <!-- sidebar-menu js -->
  <script src="../assets/js/sidebar-menu.js"></script>
  
  <!-- Custom scripts -->
  <script src="../assets/js/app-script.js"></script>
  
</body>
<script>
    // JavaScript form validation function
    function validateForm() {
        const email = document.forms["signInForm"]["email"].value;
        const password = document.forms["signInForm"]["password"].value;

        // Email validation
        const emailPattern = /^[^ ]+@[^ ]+\.[a-z]{2,3}$/;
        if (!email.match(emailPattern)) {
            alert("Please enter a valid email address.");
            return false;
        }

        // Password validation
        if (password == "") {
            alert("Password must not be empty.");
            return false;
        }

        // Password length check (optional)
        if (password.length < 6) {
            alert("Password must be at least 6 characters long.");
            return false;
        }

        // If everything is valid
        return true;
    }
</script>

</html>
