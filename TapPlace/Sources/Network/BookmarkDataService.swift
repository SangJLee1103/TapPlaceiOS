//
//  BookmarkDataService.swift
//  TapPlace
//
//  Created by 박상현 on 2022/09/22.
//

import Foundation
import Alamofire

struct BookmarkDataService {
    static let shared = BookmarkDataService()
    
    //MARK: URL
    let bookmarkUrl = "\(Constants.tapplaceApiUrl)/bookmark"
    
    /**
     * @ 즐겨찾기 불러오기
     * coder : sanghyeon
     */
    func requestFetchUserBookmark(page: Int = 1, header: HTTPHeaders, completion: @escaping (BookmarkResponseModel?) -> ()) {
        let url = "\(bookmarkUrl)/\(Constants.keyChainDeviceID)/\(page)"
        AF.request(url, method: .get, encoding: URLEncoding.default, headers: header)
            .validate()
            .responseDecodable(of: BookmarkResponseModel.self) { (response) in
                switch response.result{
                case .success(let response):
                    completion(response)
                case .failure:
                    completion(nil)
                }
            }
    }
    
    /**
     * @ 즐겨찾기 추가/삭제
     * param : isBookmark = 추가여부 (true=추가, false=삭제)
     * coder : sanghyeon
     */
    func requestFetchToggleBookmark(isBookmark: Bool, parameter: Parameters, header: HTTPHeaders?, completion: @escaping (Bool?) -> ()) {
        var method: HTTPMethod = .post
        let url = "\(bookmarkUrl)"
        switch isBookmark {
        case true:
            method = .post
        case false:
            method = .delete
        }
        AF.request(url, method: method, parameters: parameter, encoding: JSONEncoding.default, headers: header)
            .validate()
            .responseDecodable(of: AddBookmarkResponseModel.self) { (response) in
                switch response.result {
                case .success(let result):
                    if result.message == "ok" {
                        completion(true)
                    } else {
                        completion(false)
                    }
                default:
                    completion(false)
                }
                    
            }
    }
}
