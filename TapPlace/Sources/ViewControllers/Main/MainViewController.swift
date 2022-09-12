//
//  MainViewController.swift
//  TapPlace
//
//  Created by 박상현 on 2022/08/05.
//

import UIKit
import AlignedCollectionViewFlowLayout
import NMapsMap
import CoreLocation
import SnapKit
import FloatingPanel

class MainViewController: CommonViewController {
    var storageViewModel = StorageViewModel()
    var storeViewModel = StoreViewModel()
    
    var aroundStoreList: [AroundStores]?
    
    let customNavigationBar = CustomNavigationBar()
    var naverMapView: NMFMapView = NMFMapView()
    var circleOverlay: NMFCircleOverlay = NMFCircleOverlay()
    var searchBar = UIView()
    let researchButton = ResearchButton()
    var detailOverView: DetailOverView?
    var closeButton = UIButton()
    let listButton = MapButton()
    let locationButton = MapButton()
    var overlayCenterPick = UIView()
    var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    var fpc: FloatingPanelController!
    var isHiddenFloatingPanel = true
    let locationManager = CLLocationManager()
    var currentLocation: NMGLatLng?
    var cameraLocation: NMGLatLng?
    var markerList: [AroundStoreMarkerModel] = []
    var latestSelectStore: StoreTabCollectionViewCell?

    //MARK: ViewLifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNaverMap()
        setupFloatingPanel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        showDetailOverView(hide: true)
        showNavigationBar(hide: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkLocationAuth()
    }
}

//MARK: - Layout
extension MainViewController: MapButtonProtocol, ResearchButtonProtocol {
    func didTapResearchButton() {
        guard let camLocation = cameraLocation else { return }
        showInMapViewTracking(location: camLocation)
        showResearchElement(hide: true)
        let clLocation = CLLocationCoordinate2D(latitude: camLocation.lat, longitude: camLocation.lng)
        searchAroundStore(location: clLocation)
        UserInfo.cameraLocation = clLocation
    }
    /**
     * @ 우측 하단 맵 버튼 클릭 함수
     * coder : sanghyeon
     */
    @objc func didTapMapButton(_ sender: MapButton) {
        if sender == listButton.button {
            showFloatingPanel()
        } else if sender == locationButton.button {
            getUserCurrentLocation()
            guard let location = currentLocation else { return }
            moveCamera(location: location)
            showInMapViewTracking(location: location)
            searchAroundStore(location: UserInfo.userLocation)
            showResearchElement(hide: true)
            showDetailOverView(hide: true)
            resetAllMarkersSize()
        }
    }
    /**
     * @ 검색창 클릭시 액션
     * coder : sanghyeon
     */
    @objc func didTapSearchButton() {
        let vc = SearchViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    /**
     * @ 초기 레이아웃 설정
     * coder : sanghyeon
     */
    func setupView() {
        //MARK: ViewDefine
        let safeArea = view.safeAreaLayoutGuide
        let searchIcon: UIImageView = {
            let searchIcon = UIImageView()
            searchIcon.image = UIImage(systemName: "magnifyingglass")
            searchIcon.tintColor = .black
            searchIcon.layer.opacity = 0.8
            return searchIcon
        }()
        let searchButton: UIButton = {
            let searchButton = UIButton()
            searchButton.setTitle("가맹점을 찾아보세요", for: .normal)
            searchButton.setTitleColor(UIColor.init(hex: 0x000000, alpha: 0.3), for: .normal)
            searchButton.setTitleColor(UIColor.init(hex: 0x000000, alpha: 0.1), for: .highlighted)
            searchButton.titleLabel?.font = .systemFont(ofSize: CommonUtils.resizeFontSize(size: 16), weight: .regular)
            searchButton.contentHorizontalAlignment = .left
            return searchButton
        }()
        searchBar = {
            let searchBar = UIView()
            searchBar.backgroundColor = .white
            searchBar.layer.cornerRadius = 15
            searchBar.layer.applySketchShadow(color: .black, alpha: 0.12, x: 0, y: 4, blur: 8, spread: 0)
            return searchBar
        }()
        collectionView = {
            let collectionViewLayout = UICollectionViewFlowLayout()
            collectionViewLayout.scrollDirection = .horizontal
            collectionViewLayout.minimumInteritemSpacing = 5
            collectionViewLayout.minimumLineSpacing = 0
            let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), collectionViewLayout: collectionViewLayout)
            collectionView.contentInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            collectionView.backgroundColor = .clear
            collectionView.showsHorizontalScrollIndicator = false
            return collectionView
        }()
        overlayCenterPick = {
            let overlayCenterPick = UIView()
            overlayCenterPick.layer.borderColor = UIColor.red.cgColor
            overlayCenterPick.layer.borderWidth = 2
            overlayCenterPick.isHidden = true
            return overlayCenterPick
        }()
        

        //MARK: ViewPropertyManual
        view.backgroundColor = .white
        self.navigationController?.navigationBar.isHidden = true
        listButton.iconName = "list"
        listButton.layer.applySketchShadow(color: .black, alpha: 0.12, x: 0, y: 1, blur: 8, spread: 0)
        locationButton.iconName = "currentLocation"
        locationButton.layer.applySketchShadow(color: .black, alpha: 0.12, x: 0, y: 1, blur: 8, spread: 0)
        overlayCenterPick.isHidden = true
        researchButton.isHidden = true
        researchButton.layer.applySketchShadow(color: .black, alpha: 0.12, x: 0, y: 1, blur: 8, spread: 0)
        
        
        //MARK: AddSubView
        view.addSubview(searchBar)
        searchBar.addSubview(searchIcon)
        searchBar.addSubview(searchButton)
        view.addSubview(collectionView)
        view.addSubview(listButton)
        view.addSubview(locationButton)
        view.addSubview(overlayCenterPick)
        view.addSubview(researchButton)
        
        
        //MARK: ViewContraints
        searchBar.snp.makeConstraints {
            $0.top.equalTo(safeArea).offset(10)
            $0.leading.equalTo(safeArea).offset(20)
            $0.trailing.equalTo(safeArea).offset(-20)
            $0.height.equalTo(50)
        }
        searchIcon.snp.makeConstraints {
            $0.leading.equalTo(searchBar).offset(15)
            $0.centerY.equalTo(searchBar)
            $0.width.height.equalTo(20)
        }
        searchButton.snp.makeConstraints {
            $0.top.bottom.trailing.equalTo(searchBar)
            $0.leading.equalTo(searchIcon.snp.trailing).offset(10)
        }
        collectionView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(10)
            $0.leading.trailing.equalTo(safeArea)
            $0.height.equalTo(40)
        }
        listButton.snp.makeConstraints {
            $0.bottom.equalTo(safeArea).offset(-40)
            $0.trailing.equalTo(safeArea).offset(-20)
            $0.width.height.equalTo(40)
        }
        locationButton.snp.makeConstraints {
            $0.bottom.equalTo(listButton.snp.top).offset(-10)
            $0.trailing.equalTo(listButton)
            $0.width.height.equalTo(40)
        }
        overlayCenterPick.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(20)
        }
        researchButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalTo(listButton)
            $0.width.equalTo(150)
            $0.height.equalTo(30)
        }

        
        //MARK: ViewAddTarget & Register
        searchButton.addTarget(self, action: #selector(didTapSearchButton), for: .touchUpInside)
        collectionView.register(StoreTabCollectionViewCell.self, forCellWithReuseIdentifier: StoreTabCollectionViewCell.cellId)
        
        
        //MARK: Delegate
        listButton.delegate = self
        locationButton.delegate = self
        researchButton.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        
        //MARK: ViewModel
        PaymentModel.favoriteList = storageViewModel.userFavoritePayments

    }

    /**
     * @ 메인 뷰컨트롤러 오버퓨 표시
     * param : storeID 및 네비게이션 표시 여부
     * coder : sanghyeon
     */
    func showStoreInfo(storeID: String, isShowNavigation: Bool = true) {
        showDetailOverView(hide: false)
        if isShowNavigation {
            showNavigationBar(hide: false, title: "스토어 이름")
        }
    }

}
//MARK: - NaverMap
extension MainViewController: CLLocationManagerDelegate, NMFMapViewCameraDelegate {
    /**
     * @ 네이버맵 세팅
     * coder : sanghyeon
     */
    func setupNaverMap() {
        //MARK: NaverMapViewDefine
        naverMapView = NMFMapView(frame: view.frame)
        
        //MARK: NaverMapViewAddSubView
        view.addSubview(naverMapView)
        view.sendSubviewToBack(naverMapView)
        
        //MARK: LocationAuthRequest
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        //MARK: GetUserCurrentLocation & MoveCamera
        getUserCurrentLocation()
        guard let location = currentLocation else { return }
        moveCamera(location: location)
        showInMapViewTracking(location: location)
        
        //MARK: NaverMapViewDelegate
        naverMapView.addCameraDelegate(delegate: self)
    }
    /**
     * @ 사용자 현재 위치 가져오기
     * coder : sanghyeon
     */
    func getUserCurrentLocation() {
        guard let result = locationManager.location?.coordinate else { return }
        currentLocation = NMGLatLng(from: result)
        UserInfo.userLocation = result
        UserInfo.cameraLocation = result
        searchAroundStore(location: result)
    }
    /**
     * @ 네이버지도 카메라 이동
     * coder : sanghyeon
     */
    func moveCamera(location: NMGLatLng) {
        let cameraUpdate = NMFCameraUpdate(scrollTo: location, zoomTo: 14.0)
        cameraUpdate.animation = .easeIn
        cameraUpdate.animationDuration = 1
        naverMapView.moveCamera(cameraUpdate)
    }
    /**
     * @ 트래킹 표시 및 반경 오버레이
     * coder : sanghyeon
     */
    func showInMapViewTracking(location: NMGLatLng) {
        //print("현재위치 가져오기: showInMapViewTracking")
        //getUserCurrentLocation()
        guard let trackingLocation = UserInfo.userLocation else { return }
        /// 트래킹 아이콘
        let locationOverlay = naverMapView.locationOverlay
        locationOverlay.location = NMGLatLng(from: trackingLocation)
        locationOverlay.circleOutlineWidth = 0
        locationOverlay.hidden = false
        locationOverlay.subIcon = nil
        /// 반경 설정
        circleOverlay.mapView = nil
        circleOverlay = NMFCircleOverlay(location, radius: 1000)
        circleOverlay.fillColor = .pointBlue.withAlphaComponent(0.1)
        circleOverlay.outlineWidth = 1
        circleOverlay.outlineColor = .pointBlue
        circleOverlay.mapView = naverMapView
    }
    /**
     * @ 지도에 마커 추가
     * coder : sanghyeon
     */
    
    func addMarker(markers: [AroundStores]) {
        for marker in markerList {
            marker.marker.mapView = nil
        }
        markerList.removeAll()
        if markers.count <= 0 { return }
        for markerRow in markers {
            if let x = Double(markerRow.x), let y = Double(markerRow.y) {
                let markerPosition = NMGLatLng(lat: y, lng: x)
                let naverMapMarker = NMFMarker(position: markerPosition)
                naverMapMarker.isHideCollidedMarkers = true
                naverMapMarker.mapView = naverMapView
                if let markerImage = MarkerModel.list.first(where: {$0.groupName == markerRow.categoryGroupName}) {
                    naverMapMarker.iconImage = NMFOverlayImage(name: markerImage.markerImage)
                }
                naverMapMarker.captionText = markerRow.placeName
                naverMapMarker.captionRequestedWidth = 80
                naverMapMarker.isHideCollidedCaptions = true
                naverMapMarker.width = 37
                naverMapMarker.height = 47

                naverMapMarker.touchHandler = { (marker) in
                    if let marker = marker as? NMFMarker {
                        self.didTapMarker(marker: marker)
                    }
                    return true
                }
                markerList.append(AroundStoreMarkerModel(store: markerRow, marker: naverMapMarker))
            }
        }
    }
    /**
     * @ 마커 숨기기 (삭제X, 숨기기O)
     * coder : sanghyeon
     */
    func hideMarker(marker: NMFMarker?) {
        if let marker = marker {
            marker.mapView = nil
        } else {
            for addedMarker in markerList {
                addedMarker.marker.mapView = naverMapView
            }
        }
    }
    /**
     * @ 지도상 마커 사이즈 초기화
     * coder : sanghyeon
     */
    func resetAllMarkersSize() {
        for eachMarker in markerList {
            if let markerImage = MarkerModel.list.first(where: {$0.groupName == eachMarker.store.categoryGroupName}) {
                eachMarker.marker.iconImage = NMFOverlayImage(name: markerImage.markerImage)
            }
            eachMarker.marker.width = 37
            eachMarker.marker.height = 47
        }
    }
    /**
     * @ 마커 클릭 이벤트
     * coder : sanghyeon
     */
    func didTapMarker(marker: NMFMarker?) {
        /// 열려있는 오버뷰 닫기
        showDetailOverView(hide: true)
        /// 모든 마커 사이즈 초기화
        resetAllMarkersSize()
        /// 선택된 마커 사이즈 확장
        guard let marker = marker else { return }
        marker.width = 50
        marker.height = 68
        
        /// 마커의 스토어 정보
        guard let targetMarker = markerList.first(where: {$0.marker == marker }) else { return }
        let targetStore = targetMarker.store
        
        if let markerImage = MarkerModel.list.first(where: {$0.groupName == targetStore.categoryGroupName}) {
            targetMarker.marker.iconImage = NMFOverlayImage(name: "select_\(markerImage.markerImage)")
        }
        
        print("클릭된 마커의 스토어: ", targetStore.placeName)
        /// AroundStores -> StoreInfo 변환
        let targetStoreInfo = StoreInfo.convertAroundStores(aroundStore: targetStore)
        showDetailOverView(hide: false, storeInfo: targetStoreInfo)
    }
    
    
    
    //MARK: Camera
    func mapViewCameraIdle(_ mapView: NMFMapView) {
        let camPosition = naverMapView.cameraPosition
        cameraLocation = camPosition.target
    }
    func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
        if reason != -1 { return }
        showResearchElement(hide: false)
    }
    
    //MARK: Auth
    /**
     * @ 위치권한 설정
     * coder : sanghyeon
     */
    func checkLocationAuth() {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
            getUserCurrentLocation()
            guard let userLocation = UserInfo.userLocation else { return }
            showInMapViewTracking(location: NMGLatLng(from: userLocation))
        case .restricted, .notDetermined:
            getLocationUsagePermission()
        case .denied:
            let alertController = UIAlertController(title: "위치권한이 거부되었습니다.", message: "위치권한 거부시 정상적으로 앱을 이용하실 수 없습니다. 앱 설정 화면으로 이동하시겠습니까?", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "네", style: .default, handler: { (action) -> Void in
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            }))
            alertController.addAction(UIAlertAction(title: "아니오", style: .cancel, handler: { (action) -> Void in
                
            }))
            self.present(alertController, animated: true, completion: nil)
        default: break
        }
    }
    /**
     * @ 위치권한 요청
     * coder : sanghyeon
     */
    func getLocationUsagePermission() {
        self.locationManager.requestWhenInUseAuthorization()
    }
    /**
     * @ 권한이 변경 되었을때 현재 위치로 이동
     * coder : sanghyeon
     */
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            getUserCurrentLocation()
            guard let userLocation = UserInfo.userLocation else { return }
            showInMapViewTracking(location: NMGLatLng(from: userLocation))
            moveCamera(location: NMGLatLng(from: userLocation))
        }
    }
    /**
     * @ 재검색 관련 UI 토글
     * coder : sanghyeon
     */
    func showResearchElement(hide: Bool) {
        if hide {
            overlayCenterPick.isHidden = true
            researchButton.isHidden = true
        } else {
            self.overlayCenterPick.isHidden = false
            self.researchButton.isHidden = false
        }
    }
}

//MARK: - Delegate Other VC
extension MainViewController: CustomToolBarShareProtocol, StoreInfoViewDelegate {
    /**
     * @ 스토어 상세 뷰컨 이동
     * coder : sanghyeon
     */
    func moveStoreDetail(store: StoreInfo) {
        let vc = StoreDetailViewController()
        vc.storeInfo = store
        self.navigationController?.pushViewController(vc, animated: true)
    }
    /**
     * @ 공유하기
     * coder : sanghyeon
     */
    func showShare(storeInfo: StoreInfo) {
        var objectToShare = [String]()
        let shareText = "\(storeInfo.placeName)의 간편결제 정보입니다.\n\n\(Constants.tapplaceBaseUrl)/app/\(storeInfo.storeID)"
        objectToShare.append(shareText)
        
        let activityVC = UIActivityViewController(activityItems: objectToShare, applicationActivities: nil)
        self.present(activityVC, animated: true)
    }
    
    /**
     * @ 상세뷰 오버 뷰
     * coder : sanghyeon
     */
    func showDetailOverView(hide: Bool, storeInfo: StoreInfo? = nil) {
        guard let tabBar = self.tabBarController as? TabBarViewController else { return }
        if hide {
            guard let detailOverView = detailOverView else { return }
            detailOverView.removeFromSuperview()
            closeButton.removeFromSuperview()
            detailOverView.snp.removeConstraints()
            tabBar.showTabBar(hide: false)
            locationButton.snp.remakeConstraints {
                $0.bottom.equalTo(listButton.snp.top).offset(-20)
                $0.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
                $0.width.height.equalTo(40)
            }
            tabBar.showTabBar(hide: false)
        } else {
            detailOverView = DetailOverView()
            guard let detailOverView = detailOverView else { return }
            fpc.move(to: .hidden, animated: true)
            closeButton = {
                let closeButton = UIButton()
                closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
                closeButton.tintColor = .black
                return closeButton
            }()
            closeButton.addTarget(self, action: #selector(didTapDetailOverViewCloseButton), for: .touchUpInside)
            view.addSubview(detailOverView)
            detailOverView.addSubview(closeButton)
            detailOverView.snp.makeConstraints {
                $0.leading.trailing.bottom.equalToSuperview()
                $0.top.equalTo(detailOverView.storeInfoView)
            }
            closeButton.snp.makeConstraints {
                $0.trailing.equalTo(detailOverView).offset(-20)
                $0.centerY.equalTo(detailOverView.storeInfoView.storeLabel)
                $0.width.height.equalTo(20)
            }
            
            detailOverView.storeInfoView.titleSize = .large
            detailOverView.toolBar.vcDelegate = self
            detailOverView.storeInfoView.delegate = self

            if let storeInfo = storeInfo {
                detailOverView.storeInfo = storeInfo
            }

            detailOverView.layer.applySketchShadow(color: .black, alpha: 0.12, x: 0, y: 0, blur: 14, spread: 0)
            locationButton.snp.remakeConstraints {
                $0.bottom.equalTo(detailOverView.snp.top).offset(-20)
                $0.trailing.equalTo(view.safeAreaLayoutGuide).offset(-20)
                $0.width.height.equalTo(40)
            }
            tabBar.showTabBar(hide: true)
        }
    }
    @objc func didTapDetailOverViewCloseButton() {
        showDetailOverView(hide: true)
        resetAllMarkersSize()
    }
    /**
     * @ 네비게이션바 표시
     * coder : sanghyeon
     */
    func showNavigationBar(hide: Bool, title: String = "") {
        if hide {
            customNavigationBar.removeFromSuperview()
            searchBar.isHidden = false
            collectionView.isHidden = false
        } else {
            searchBar.isHidden = true
            collectionView.isHidden = true
            let rightButton: UIButton = {
                let rightButton = UIButton()
                rightButton.tintColor = .black
                rightButton.setImage(UIImage(systemName: "xmark"), for: .normal)
                rightButton.addTarget(self, action: #selector(didTapNavigationRightButton), for: .touchUpInside)
                return rightButton
            }()
            
            view.addSubview(customNavigationBar)
            customNavigationBar.addSubview(rightButton)
            customNavigationBar.snp.makeConstraints {
                $0.top.leading.trailing.equalToSuperview()
                $0.bottom.equalTo(customNavigationBar.containerView)
            }
            rightButton.snp.makeConstraints {
                $0.trailing.equalTo(customNavigationBar).offset(-10)
                $0.bottom.equalTo(customNavigationBar).offset(-10)
                $0.width.height.equalTo(30)
            }
            customNavigationBar.titleText = title
            customNavigationBar.isUseLeftButton = true
            customNavigationBar.isDrawShadow = true
        }
    }
    /**
     * @ 네비게이션바 우측 버튼 클릭 함수
     * coder : sanghyeon
     */
    @objc func didTapNavigationRightButton() {
        showNavigationBar(hide: true)
        showDetailOverView(hide: true)
    }
}
//MARK: - 뷰모델 함수
extension MainViewController {
    /**
     * @ 좌표 기준으로 주변 매장 검색 후 마커 표시
     * coder : sanghyeon
     */
    func searchAroundStore(location: CLLocationCoordinate2D?) {
        guard let location = location else { return }
        storeViewModel.requestAroundStore(location: location, pays: storageViewModel.userFavoritePaymentsString) { result in
            guard let result = result else { return }
            AroundStoreModel.list = result.stores
            self.addMarker(markers: result.stores)
        }
    }
}


//MARK: - CollectionView
extension MainViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    /// 컬렉션뷰 셀 개수 반환
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return StoreModel.lists.count
    }
    /// 컬렉션뷰 셀 설정
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StoreTabCollectionViewCell.cellId, for: indexPath) as! StoreTabCollectionViewCell
        if let icon = UIImage(named: StoreModel.lists[indexPath.row].id) {
            cell.icon = icon
            cell.iconColor = StoreModel.lists[indexPath.row].color
        } 
        cell.itemText.text = StoreModel.lists[indexPath.row].title
        cell.storeId = StoreModel.lists[indexPath.row].id
        return cell
    }
    /// 컬렉션뷰 선택시 필터 적용
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? StoreTabCollectionViewCell else { return }
        latestSelectStore?.cellSelected = false
        /// 이미 선택 된 셀을 클릭했을때
        if cell == latestSelectStore {
            latestSelectStore = nil
            hideMarker(marker: nil)
            return
        } else {
            cell.cellSelected = true
            latestSelectStore = cell
            hideMarker(marker: nil)
            let storeCategory = cell.itemText.text == "기타" ? "" : cell.itemText.text
            for marker in markerList {
                
                if marker.store.categoryGroupName != storeCategory {
                    hideMarker(marker: marker.marker)
                }
            }
        }
    }
    /// 컬렉션뷰 셀 라벨 사이즈 대비 사이즈 변경
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let labelSize = CommonUtils.getTextSizeWidth(text: StoreModel.lists[indexPath.row].title)
        return CGSize(width: labelSize.width + 35, height: 28)
    }
}


//MARK: - Floating Panel
extension MainViewController: FloatingPanelControllerDelegate, AroundPlaceMainControllerProtocol {
    /**
     * @ 플로팅패널 확장 함수
     * coder : sanghyeon
     */
    func expendFloatingPanel() {
        fpc.move(to: .full, animated: true)
    }
    /**
     * @ 플로팅패널 설정
     * coder : sanghyeon
     */
    func setupFloatingPanel() {
        fpc = FloatingPanelController()
        fpc.delegate = self
        fpc.surfaceView.grabberHandlePadding = 10.0
        fpc.surfaceView.grabberHandleSize = .init(width: 44.0, height: 4.0)
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        fpc.contentMode = .fitToBounds
        
        // Create a new appearance.
        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 20.0
        appearance.backgroundColor = .white

        // Set the new appearance
        fpc.surfaceView.appearance = appearance
    }
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
            return MainFloatingPanelLayout()
    }
    func floatingPanelDidChangeState(_ fpc: FloatingPanelController) {
        if fpc.state == .hidden {
            fpc.surfaceView.grabberHandle.isHidden = false
        }
    }
    /**
     * @ 플로팅패널 보이기
     * coder : sanghyeon
     */
    func showFloatingPanel(type: FloatingPanelState = .half) {
        /// addPanel의 경우 뷰컨을 새로 로드하기 때문에, removesubview한게 사라짐
        /// 그래서 상태에 따라서 addpanel및 set을 따로 줌
        if fpc.state == type { return }
        if fpc.state == .hidden {
            let contentVC = AroundPlaceViewController()
            fpc.addPanel(toParent: self)
            fpc.track(scrollView: contentVC.aroundPlaceListView.tableView)
            fpc.set(contentViewController: contentVC)
            contentVC.aroundPlaceListView.mainDelegate = self
        }
        fpc.move(to: type, animated: true)
    }
    /**
     * @ 그래버 숨기기
     * coder : sanghyeon
     */
    func hideGrabber(hide: Bool = false) {
        fpc.surfaceView.grabberHandle.isHidden = hide
    }
    
//    func floatingPanelWillEndDragging(_ fpc: FloatingPanelController, withVelocity velocity: CGPoint, targetState: UnsafeMutablePointer<FloatingPanelState>) {
//        if targetState.pointee == .hidden {
//            guard let tabBar = self.tabBarController as? TabBarViewController else { return }
//            tabBar.showTabBar(hide: false)
//        }
//    }
    
}

class MainFloatingPanelLayout: FloatingPanelLayout {
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .hidden
    var anchors: [FloatingPanel.FloatingPanelState : FloatingPanel.FloatingPanelLayoutAnchoring]{
        return [
            .full: FloatingPanelLayoutAnchor(absoluteInset: 110.0, edge: .top, referenceGuide: .safeArea),
            .half: FloatingPanelLayoutAnchor(fractionalInset: 0.29, edge: .bottom, referenceGuide: .safeArea),
            .hidden: FloatingPanelLayoutAnchor(absoluteInset: 0, edge: .bottom, referenceGuide: .safeArea),
        ]
    }
    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        switch state {
        case .full: return 0.7
        default: return 0.0
        }
    }
}
