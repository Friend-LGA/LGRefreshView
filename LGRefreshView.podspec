Pod::Spec.new do |s|

    s.name = 'LGRefreshView'
    s.version = '1.0.1'
    s.platform = :ios, '6.0'
    s.license = 'MIT'
    s.homepage = 'https://github.com/Friend-LGA/LGRefreshView'
    s.author = { 'Grigory Lutkov' => 'Friend.LGA@gmail.com' }
    s.source = { :git => 'https://github.com/Friend-LGA/LGRefreshView.git', :tag => s.version }
    s.summary = 'iOS pull to refresh for UIScrollView, UITableView and UICollectionView'

    s.requires_arc = true

    s.source_files = 'LGRefreshView/*.{h,m}'

    s.dependency 'DACircularProgress', '~> 2.3.1'

end
