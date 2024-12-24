package Main.Schedule.act;

import Main.Schedule.GameData;
import Main.Schedule.object.Dynasty;
import Main.Schedule.object.Person;

public class settled {
	public static GameData act(GameData gamedata, int num) {
		Dynasty dynasty = gamedata.getDynasties().get(num);
		int act = (int) (Math.random()*3);
		switch (act) {
			case 0:
				System.out.print(dynasty.getLocation().getName()+"에서 생산직! ");
				dynasty.setMoney(dynasty.getMoney()+2); //평균 기대 수입
				break;
			case 1:
				System.out.print(dynasty.getLocation().getName()+"에서 가공직? ");
				dynasty.setMoney(dynasty.getMoney()+(int) (Math.random()*5)); //0,1,2,3,4 중 랜덤 수입
				break;
			case 2:
				System.out.print(dynasty.getLocation().getName()+"에서 고위직!? ");
				dynasty.setMoney(dynasty.getMoney()+4); //최대 기대 수입
				break;
			default:
				System.out.print(dynasty.getLocation().getName()+"에서 무직.. ");	//무수입
				break;
		}
		
		//만나면 결혼
		Person a = dynasty.getMember().get((int) (Math.random()*dynasty.getMember().size()));
		if(!a.isMarried()) {
			//현 위치에서 랜덤 가문 선택, 거기서 랜덤 인원 선택
			Dynasty B = dynasty.getLocation().getSettled().get((int) (Math.random()*dynasty.getLocation().getSettled().size()));
			Person b = B.getMember().get((int) (Math.random()*B.getMember().size()));
			if(!b.isMarried() && a.getGender()!=b.getGender() && B!=dynasty) {
				//결혼 조건이 맞으면 진행
				System.out.print("/ "+dynasty.getName()+"의 "+a.getName()+"와 "+B.getName()+"의 "+b.getName()+"가 결혼하였습니다. ");
				B.getMember().remove(b);
				if(B.getMember().size()==0) {
					System.out.print("/ "+B.getName()+"이 흡수됨");
					dynasty.getLocation().getSettled().remove(B);
					gamedata.getDynasties().remove(B);
				}
				dynasty.getMember().add(b);
				a.setMarried(true);
				b.setMarried(true);
				int rand = (int) (Math.random()*4)+1;
				for (int i = 0; i < rand; i++) {
					Person baby = new Person(gamedata.getId(), "이름"+(gamedata.getId()-1), (int) (Math.random()*2), 0, dynasty);
					dynasty.getMember().add(baby);
					System.out.print("/ "+baby.getName()+"이 태어남");
				}
			}
		}else {
			//기혼자(독거 가문 제외)라면 군 입대, 보상 100G 일시불 / 10G 봉급
			if((int) (Math.random()*4)==0) {
				if(dynasty.getMember().size()>1 && dynasty.getLocation().getMoney() >= 100) {
					dynasty.getMember().remove(a);
					dynasty.getLocation().getArmy().add(a);
					dynasty.setMoney(dynasty.getMoney()+100);
					dynasty.getLocation().setMoney(dynasty.getLocation().getMoney()-100);
					System.out.print("/ "+dynasty.getName()+"의 "+a.getName()+"이 군 입대 함");
				}
			}
			
		}
	
		System.out.println();
		return gamedata;
	}
}
