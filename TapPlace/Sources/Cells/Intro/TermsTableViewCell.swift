//
//  TermsTableViewCell.swift
//  TapPlace
//
//  Created by 박상현 on 2022/08/25.
//

import UIKit

class TermsTableViewCell: UITableViewCell {
    static let cellId = "termsItem"
    
    let cellView = TermsItemView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super .init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell() {
        
        
        addSubview(cellView)
        
        cellView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}
