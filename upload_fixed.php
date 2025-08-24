<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Set headers
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Log the request
error_log("Upload request received. Method: " . $_SERVER['REQUEST_METHOD']);
error_log("Files: " . json_encode($_FILES));
error_log("POST: " . json_encode($_POST));

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        "success" => false, 
        "message" => "Method not allowed. Use POST."
    ]);
    exit();
}

if (empty($_FILES)) {
    echo json_encode([
        "success" => false, 
        "message" => "No files uploaded. Files array is empty."
    ]);
    exit();
}

// Configuration
$allowedExts = ['jpg', 'jpeg', 'png', 'gif'];
$allowedMimes = ['image/jpeg', 'image/png', 'image/gif'];
$maxFileSize = 5 * 1024 * 1024; // 5MB
$maxFiles = 10;

// Create upload directory
$uploadBase = 'uploads/';
$targetDir = $uploadBase . date('Y') . '/' . date('m') . '/';
if (!is_dir($targetDir)) {
    if (!mkdir($targetDir, 0755, true)) {
        echo json_encode([
            "success" => false, 
            "message" => "Failed to create upload directory: $targetDir"
        ]);
        exit();
    }
}

// Compression function
function compressImage($source, $destination, $mime, $quality = 70) {
    try {
        switch ($mime) {
            case 'image/jpeg':
                $image = imagecreatefromjpeg($source);
                if (!$image) return false;
                $result = imagejpeg($image, $destination, $quality);
                imagedestroy($image);
                return $result;
            case 'image/png':
                $image = imagecreatefrompng($source);
                if (!$image) return false;
                // PNG compression: 0 (no) - 9 (max). 9 = smallest file.
                $result = imagepng($image, $destination, 9);
                imagedestroy($image);
                return $result;
            case 'image/gif':
                $image = imagecreatefromgif($source);
                if (!$image) return false;
                $result = imagegif($image, $destination);
                imagedestroy($image);
                return $result;
            default:
                return false;
        }
    } catch (Exception $e) {
        error_log("Image compression error: " . $e->getMessage());
        return false;
    }
}

// Process uploaded files
$uploadedUrls = [];
$errors = [];

// Check for both 'images' and 'images[]' field names
$fileField = null;
if (isset($_FILES['images'])) {
    $fileField = 'images';
} elseif (isset($_FILES['images[]'])) {
    $fileField = 'images[]';
} else {
    // Check all file fields
    foreach ($_FILES as $fieldName => $fileData) {
        $fileField = $fieldName;
        break;
    }
}

if (!$fileField) {
    echo json_encode([
        "success" => false, 
        "message" => "No file field found. Available fields: " . implode(', ', array_keys($_FILES))
    ]);
    exit();
}

error_log("Using file field: $fileField");

// Handle multiple files
if (is_array($_FILES[$fileField]['name'])) {
    $fileCount = count($_FILES[$fileField]['name']);
    error_log("Processing $fileCount files");
    
    if ($fileCount > $maxFiles) {
        echo json_encode([
            "success" => false, 
            "message" => "Too many files. Maximum $maxFiles allowed."
        ]);
        exit();
    }
    
    for ($i = 0; $i < $fileCount; $i++) {
        if ($_FILES[$fileField]['error'][$i] !== UPLOAD_ERR_OK) {
            $errors[] = "File $i upload error: " . $_FILES[$fileField]['error'][$i];
            continue;
        }
        
        $originalName = $_FILES[$fileField]['name'][$i];
        $tmpName = $_FILES[$fileField]['tmp_name'][$i];
        $fileSize = $_FILES[$fileField]['size'][$i];
        $fileExt = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
        
        // Validate extension
        if (!in_array($fileExt, $allowedExts)) {
            $errors[] = "Invalid file type for $originalName. Allowed: " . implode(', ', $allowedExts);
            continue;
        }
        
        // Validate MIME type
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mime = finfo_file($finfo, $tmpName);
        finfo_close($finfo);
        
        if (!in_array($mime, $allowedMimes)) {
            $errors[] = "Invalid MIME type for $originalName: $mime";
            continue;
        }
        
        // Validate file size
        if ($fileSize > $maxFileSize) {
            $errors[] = "File $originalName is too large: " . number_format($fileSize / 1024 / 1024, 2) . "MB";
            continue;
        }
        
        // Generate unique filename
        $uniqueName = uniqid("img_") . '_' . time() . '.' . $fileExt;
        $targetFile = $targetDir . $uniqueName;
        
        // Compress and save
        if (compressImage($tmpName, $targetFile, $mime, 70)) {
            $uploadedUrls[] = 'https://wzsgame.com/' . $targetFile;
            error_log("Successfully uploaded: $targetFile");
        } else {
            $errors[] = "Failed to compress/save $originalName";
        }
    }
} else {
    // Single file
    if ($_FILES[$fileField]['error'] !== UPLOAD_ERR_OK) {
        echo json_encode([
            "success" => false, 
            "message" => "File upload error: " . $_FILES[$fileField]['error']
        ]);
        exit();
    }
    
    $originalName = $_FILES[$fileField]['name'];
    $tmpName = $_FILES[$fileField]['tmp_name'];
    $fileSize = $_FILES[$fileField]['size'];
    $fileExt = strtolower(pathinfo($originalName, PATHINFO_EXTENSION));
    
    // Validate extension
    if (!in_array($fileExt, $allowedExts)) {
        echo json_encode([
            "success" => false, 
            "message" => "Invalid file type. Allowed: " . implode(', ', $allowedExts)
        ]);
        exit();
    }
    
    // Validate MIME type
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mime = finfo_file($finfo, $tmpName);
    finfo_close($finfo);
    
    if (!in_array($mime, $allowedMimes)) {
        echo json_encode([
            "success" => false, 
            "message" => "Invalid MIME type: $mime"
        ]);
        exit();
    }
    
    // Validate file size
    if ($fileSize > $maxFileSize) {
        echo json_encode([
            "success" => false, 
            "message" => "File too large: " . number_format($fileSize / 1024 / 1024, 2) . "MB"
        ]);
        exit();
    }
    
    // Generate unique filename
    $uniqueName = uniqid("img_") . '_' . time() . '.' . $fileExt;
    $targetFile = $targetDir . $uniqueName;
    
    // Compress and save
    if (compressImage($tmpName, $targetFile, $mime, 70)) {
        $uploadedUrls[] = 'https://wzsgame.com/' . $targetFile;
        error_log("Successfully uploaded: $targetFile");
    } else {
        echo json_encode([
            "success" => false, 
            "message" => "Failed to compress/save image"
        ]);
        exit();
    }
}

// Return response
if (count($uploadedUrls) > 0) {
    echo json_encode([
        "success" => true, 
        "urls" => $uploadedUrls,
        "uploaded" => count($uploadedUrls),
        "errors" => $errors
    ]);
} else {
    echo json_encode([
        "success" => false, 
        "message" => "No images were uploaded successfully",
        "errors" => $errors
    ]);
}
?>
