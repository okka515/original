document.addEventListener('DOMContentLoaded', function() {
    if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(function(position) {
            document.getElementById('latitude').value = position.coords.latitude;
            document.getElementById('longitude').value = position.coords.longitude;
        }, function(error) {
            console.error("位置情報の取得に失敗しました: ", error);
        });
    } else {
        console.error("位置情報の取得はサポートされていません。");
    }
});
