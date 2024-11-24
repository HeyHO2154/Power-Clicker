import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.Scanner;

public class Mafia {
	//기본 변수
	static int N = 10;
	static String[] player = new String[N];
	static int[] personal = new int[N]; //명예로움,순수함,이기적인,사악한 - 1,2,3,4
	static int[] Job = new int[N]; //시민,마피아,경찰,의사 - 1,2,3,4
	static int[] Job_claim = new int[N]; //본인 주장 직업
	//인게임 변수
	static Map<Integer, List<Integer>> Alive = new HashMap<>(); //시민팀,마피아팀 - 1,2
	static Map<Integer, List<Integer>> Enemy = new HashMap<>(); //적대 리스트
	static int[] pick = new int[N]; //직업으로의 선택
	static int[] pick_claim = new int[N]; //직업으로의 선택(본인피셜)
	static int[] suspect_num = new int[N]; //의심 수치
	static int[] vote = new int[N]; //투표
	//시스템 변수
	static int kill; //마피아가 죽일 타겟
	static int live; //의사가 살릴 타겟
	static int[] find = new int[N]; //조사 리스트(경찰 기록용) : 시민팀,마피아팀 - 1,2 
	static int[] find_claim = new int[N]; //조사 리스트(마피아 조작본) : 시민팀,마피아팀 - 1,2
	
	public static void main(String[] args) {
		Scanner sc = new Scanner(System.in);
		
		//게임 인원 참여
		for (int i = 0; i < N; i++) {
			personal[i] = (int) (Math.random()*4)+1;	
			Enemy.putIfAbsent(i, new ArrayList<>());
		}
		Queue<Integer> Job_temp = new LinkedList<>();
		for (int i = 0; i < N-4; i++) {
			Job_temp.add(1);
		}
		Job_temp.add(2);
		Job_temp.add(2);
		Job_temp.add(3);
		Job_temp.add(4);
		while(!Job_temp.isEmpty()) {
			int rand = (int) (Math.random()*Job.length);
			if(Job[rand]==0) {
				Job[rand] = Job_temp.poll();
				if (Job[rand] != 2) {
				    Alive.putIfAbsent(1, new ArrayList<>());
				    Alive.get(1).add(rand);
				} else {
				    Alive.putIfAbsent(2, new ArrayList<>());
				    Alive.get(2).add(rand);
				}
			}
		}
		Queue<String> users = new LinkedList<>();
		users.add("junma97");
		while(!users.isEmpty()) {
			int rand = (int) (Math.random()*player.length);
			if(player[rand]==null) {
				player[rand] = users.poll();
			}
		}
		
		//게임 진행
		while (Alive.get(2).size() > 0 && Alive.get(2).size() < Alive.get(1).size()) {
			//밤
			System.out.println("밤이 되었습니다..");
			kill = -1; //죽일 타겟 초기화
			live = -1; //살릴 대상 초기화
			for (int i = 0; i < N; i++) {
				if(Alive.get(1).contains(i) || Alive.get(2).contains(i)) {
					if(player[i]!=null) {
						System.out.println("당신은 "+i+"이고, 직업은 "+Job[i]+"입니다.");
						int who = -1;
						switch (Job[i]) {
						case 1:
							System.out.println("잠을 잡니다..");
							break;
						case 2:
							System.out.println("누구를 죽입니까?");
							System.out.println(Alive.get(2));
							who = sc.nextInt();
							Kill(i, who);
							break;
						case 3:
							System.out.println("누구를 조사합니까?");
							who = sc.nextInt();
							Find(i, who);
							break;
						case 4:
							System.out.println("누구를 살립니까?");
							who = sc.nextInt();
							Live(i, who);
							break;
						}
					}else {
						AI_Night(i);
					}
				}
			}
			//살인 유효성 검사
			if(kill!=live && kill!=-1) {
				System.out.println(kill+"이 죽었습니다.");
				Kick(kill);
			}else {
				System.out.println("아무도 죽지 않았습니다.");
			}
			
			//낮
			System.out.println("낮이 되었습니다!");
			System.out.println(AliveAll());
			suspect_num = new int[N]; //공론화 초기화
			for (int i = 0; i < N; i++) {
				if(Alive.get(1).contains(i) || Alive.get(2).contains(i)) {
					if(player[i]!=null) {
						System.out.println("1.의심하기 2.직업공개 3.방어하기");
						int action = sc.nextInt();
						switch(action){
							case 1:
								System.out.println("누구를 의심합니까?");
								int who = sc.nextInt();
								Suspect(i, who, 1);
								break;
							case 2:
								if(Alive.get(2).contains(i)) {
									if(Job_claim[i]==0) {
										System.out.println("거짓말할 직업 번호를 작성하세요(1:시민,2:마피아,3:경찰,4:의사)");						
										Job_claim[i] = sc.nextInt();
									}
									if(Job_claim[i]>=3) {
										System.out.println("누구를 대상으로 직업활동을 했는지 거짓 번호를 적으세요");
										pick_claim[i] = sc.nextInt();
										if(Job_claim[i]==3) {
											System.out.println("조사결과를 어떻게 거짓말 하시겠습니까?(1:시민팀,2:마피아팀)");
											find_claim[pick_claim[i]] = sc.nextInt();
										}
									}
								}
								OpenJob(i);
								break;
							case 3:
								Nothing(i);
								break;
						}
					}else {
						AI_Day(i);
					}
					//동일직업은 "의견내기" 무조건 시행
					for (int j = 0; j < Job_claim.length; j++) {
						if(Job_claim[i]==Job_claim[j] && i!=j && Job_claim[i]!=0 && AliveAll().contains(j)) {
							if(Job_claim[i]==3) {
								System.out.println(i+": 제가 진짜 경찰인데, "+j+"가 거짓말하네요?");
								if(Job[i]==3) find[j] = 2;	//본인이 경찰인데 맞경은 무조건 확정 마피아
								Suspect(i, j, 3);
							}else if(Job_claim[i]==4){
								System.out.println(i+": 제가 진짜 의사인데, "+j+"가 거짓말하네요?");
								Suspect(i, j, 3);
							}
							
						}
					}
				}	
			}
			//투표
			System.out.println("투표를 시작합니다.");
			vote = new int[N]; //투표 초기화
			int who = -1;
			for (int i = 0; i < N; i++) {
				if(player[i]!=null && AliveAll().contains(i)) {
					System.out.println("누구를 투표합니까?");
					who = sc.nextInt();
				}
			}
			for (int i = 0; i < N; i++) {
				if(Alive.get(1).contains(i) || Alive.get(2).contains(i)) {
					if(player[i]!=null) {
						Vote(i, who);
					}else {
						AI_Vote(i);
					}
				}	
			}
			//투표 유효성 검사(동률은 세이브)
			List<Integer> prisoner = new ArrayList<>();
			prisoner = FindMaxNum(vote);
			System.out.println(Arrays.toString(vote));
			if(prisoner.size()==1) {
				System.out.println(prisoner.get(0)+"이 투표로 처형되었습니다.");
				Kick(prisoner.get(0));
			}else {
				System.out.println("최다득표가 나오지 않아, 투표가 무산됩니다.");
			}
		}
		
		//결과
		if(Alive.get(2).size() == 0) {
			System.out.println("시민 승!");
		}else {
			System.out.println("마피아 승!");
		}
		System.out.println(Arrays.toString(Job));
		
		sc.close();
	}
	
	//밤 행동 메서드
	static void Kill(int a, int b) {
		pick[a] = b;
		if(kill==-1) {
			kill = b;
		}else{
			if((int) (Math.random()*2)==0) kill = b;
		}
	}
	static void Live(int a, int b) {
		pick[a] = b;
		live = b;
	}
	static void Find(int a, int b) {
		pick[a] = b;
		if(Job[b]==2) {
			find[b] = 2;
			if(player[a]!=null) System.out.println("마피아가 맞습니다!");
		}else {
			find[b] = 1;
			if(player[a]!=null) System.out.println("마피아가 아닙니다..");
		}
	}
	
	//a->b 공론화
	static void Suspect(int a, int b, int c) {
		Enemy.get(b).add(a);
		suspect_num[b]++;
		//경찰은 공론화+1
		if(Job_claim[a]==3) {
			Enemy.get(b).add(a);
			suspect_num[b]++;
		}
		switch(c){
			case 1:
				System.out.println(a+": 이건 "+b+"가 마피아 같은데..");
				break;
			case 2:
				System.out.println(a+": 너 아까 나 선동했지? "+b+"가 마피아네!");
				break;
			case 3:
				System.out.println(a+": "+b+"가 마피아입니다 "+b+" 꼭 투표하세요!");
				break;
			case 4:
				System.out.println(a+": 내가 볼떈 "+b+"가 의심스러움ㅋㅋ");
				break;
		}
	}
	//직업공개
	static void OpenJob(int i) {
		if(Job[i]==2 && player[i]==null) FakeJob(i);
		if(Job_claim[i]==0 && Alive.get(1).contains(i)) Job_claim[i] = Job[i];
		switch(Job[i]){
			case 1:
				System.out.println(i+": 저는 시민이에요");
				break;
			case 2:
				switch(Job_claim[i]){
				case 1:
					System.out.println(i+": 저는 시민이에요");
					break;
				case 2:
					System.out.println(i+": 저는 시민이에요");
					break;
				case 3:
					System.out.println(i+": 저는 경찰이고, 조사결과 "+pick_claim[i]+"는 "+find_claim[pick_claim[i]]+"입니다.");
					if(find_claim[pick_claim[i]]==2) Suspect(i, pick_claim[i], 3);
					break;
				case 4:
					if(i==pick_claim[i]) {
						System.out.println(i+": 저는 의사고, 저 살렸습니다ㅋ");
					}else {
						System.out.println(i+": 저는 의사고, 살린 사람은 "+pick_claim[i]+"입니다.");
					}
					break;
				}
				break;
			case 3:
				System.out.println(i+": 저는 경찰이고, 조사결과 "+pick[i]+"는 "+find[pick[i]]+"입니다.");
				if(Job[pick[i]]==2) Suspect(i, pick[i], 3);
				break;
			case 4:
				if(i==pick[i]) {
					System.out.println(i+": 저는 의사고, 저 살렸습니다ㅋ");
				}else {
					System.out.println(i+": 저는 의사고, 살린 사람은 "+pick[i]+"입니다.");
				}
				break;
		}
	}
	static void Nothing(int i) {
		if(suspect_num[i]>0) {
			System.out.println(i+": 갑자기 날 의심하네ㄷㄷ");
			suspect_num[i]--;
		}else {
			System.out.println(i+": 누구지..");
		}
	}
	
	//a->b 투표
	static void Vote(int a, int b) {
		vote[b]++;
		System.out.println(a+"가 "+b+"에게 투표 하였습니다.");
	}
	//게임에서 추방
	static void Kick(int i) {
		//생존자 명단에서 제거
		Alive.get(1).remove(Integer.valueOf(i));
		Alive.get(2).remove(Integer.valueOf(i));
		//적대 목록에서 제거(본인과 타인 모두)
		Enemy.remove(Integer.valueOf(i));
		for (Integer key : Enemy.keySet()) {
			Enemy.get(key).removeAll(List.of(i));
		}
	}
	
	//AI 행동 - 밤
	static void AI_Night(int i) { 
		List<Integer> list = new ArrayList<>();
		if(Alive.get(1).contains(i)) {
			switch (personal[i]) {
			case 1:	
				switch(Job[i]) {
					case 3:
						//특수 직업, 랜덤 순으로 조사
						list = new ArrayList<>();
						for (int j = 0; j < Job_claim.length; j++) {
							if((Job_claim[j]==3 || Job_claim[j]==4) && AliveAll().contains(j) && i!=j) list.add(j);
						}
						if(!list.isEmpty()) {
							Find(i, RandomWho(list, i));
						}else {
							Find(i, RandomWho(AliveAll(), i));
						}
						break;
					case 4:
						//특수 직업, 랜덤 순으로 치료
						list = new ArrayList<>();
						for (int j = 0; j < Job_claim.length; j++) {
							if((Job_claim[j]==3 || Job_claim[j]==4) && AliveAll().contains(j) && i!=j) list.add(j);
						}
						if(!list.isEmpty()) {
							Live(i, RandomWho(list, i));
						}else {
							Live(i, RandomWho(AliveAll(), i));
						}
						break;
				}
				break;
			case 2:
				switch(Job[i]) {
					case 3:
						//무지성 조사
						Find(i, RandomWho(AliveAll(), i));
						break;
					case 4:
						//무지성 치료
						Live(i, RandomWho(AliveAll(), i));
						break;
				}
				break;
			case 3:
				switch(Job[i]) {
					case 3:
						//특수 직업, 적대인물, 랜덤 순으로 조사
						list = new ArrayList<>();
						for (int j = 0; j < Job_claim.length; j++) {
							if((Job_claim[j]==3 || Job_claim[j]==4) && AliveAll().contains(j) && i!=j) list.add(j);
						}
						if(!list.isEmpty()) {
							Find(i, RandomWho(list, i));
						}else if(!Enemy.get(i).isEmpty()){
							Find(i, RandomWho(Enemy.get(i), i));
						}else {
							Find(i, RandomWho(AliveAll(), i));
						}
						break;
					case 4:
						//무지성 치료
						Live(i, RandomWho(AliveAll(), i));
						break;
				}
				break;
			case 4:
				switch(Job[i]) {
					case 3:
						//적대인물, 랜덤 순으로 조사
						if(!Enemy.get(i).isEmpty()){
							Find(i, RandomWho(Enemy.get(i), i));
						}else {
							Find(i, RandomWho(AliveAll(), i));
						}
						break;
					case 4:
						//본인만 치료
						Live(i,i);
						break;
				}
				break;
			}
		}else if(Alive.get(2).contains(i)) {
			switch (personal[i]) {
			case 1:
				//특수 직업, 랜덤 순으로 살인
				list = new ArrayList<>();
				for (int j = 0; j < Job_claim.length; j++) {
					if((Job_claim[j]==3 || Job_claim[j]==4) && Alive.get(1).contains(j) && i!=j) list.add(j);
				}
				if(!list.isEmpty()) {
					Kill(i, RandomWho(list, i));
				}else {
					Kill(i, RandomWho(Alive.get(1), i));
				}
				break;
			case 2:
				//랜덤 살인
				Kill(i, RandomWho(Alive.get(1), i));
				break;
			case 3:
				//특수 직업, 적대인물, 랜덤 순으로 살인
				list = new ArrayList<>();
				for (int j = 0; j < Job_claim.length; j++) {
					if((Job_claim[j]==3 || Job_claim[j]==4) && Alive.get(1).contains(j) && i!=j) list.add(j);
				}
				if(!list.isEmpty()) {
					Kill(i, RandomWho(list, i));
				}else if(!Enemy.get(i).isEmpty()){
					Kill(i, RandomWho(Enemy.get(i), i));
				}else {
					Kill(i, RandomWho(Alive.get(1), i));
				}
				break;
			case 4:
				//적대인물 살인이나, 랜덤 살인
				if(!Enemy.get(i).isEmpty()){
					Kill(i, RandomWho(Enemy.get(i), i));
				}else {
					Kill(i, RandomWho(Alive.get(1), i));
				}
				break;
			}
		}
	}
	
	//AI 행동 - 낮
	static void AI_Day(int i) {
		if(Alive.get(1).contains(i)) {
			switch (personal[i]) {
			case 1:
				//시민이 매판 불리해서 이점 적용해줌
				if(Job[i]==3) {
					pick[i] = RandomWho(Alive.get(2), i);	//엄청난 추리력
					find[pick[i]] = 2;
					OpenJob(i);
				}else {
					Suspect(i, RandomWho(Alive.get(2), i), 1); //엄청난 직감
				}				
				break;
			case 2:
				//가만있다가 후반에 직업공개
				if(AliveAll().size()>N/2) {
					Nothing(i);
				}else {
					OpenJob(i);
				}		
				break;
			case 3:
				//직업공개(경찰), 적대인물 의심, 직업공개 순
				if(Job[i]==3) {
					OpenJob(i);
				}else if(!Enemy.get(i).isEmpty()) {
					Suspect(i, RandomWho(Enemy.get(i), i), 2);
				}else {
					OpenJob(i);
				}
				break;
			case 4:
				//적대인물 또는 아무나 의견내기
				if(!Enemy.get(i).isEmpty()) {
					Suspect(i, RandomWho(Enemy.get(i), i), 2);
				}else {
					Suspect(i, RandomWho(AliveAll(), i), 4);
				}
				break;
			}
		}else if(Alive.get(2).contains(i)) {
			//마피아 일때,
			switch (personal[i]) {
			case 1:
				//경찰, 의사 주장자 있으면 공론화, 그 외 가짜 직업
				List<Integer> list = new ArrayList<>();
				for (int j = 0; j < Job_claim.length; j++) {
					if((Job_claim[j]==3 || Job_claim[j]==4) && Alive.get(1).contains(j) && i!=j) list.add(j);
				}
				if(!list.isEmpty()) {
					Suspect(i, RandomWho(list, i), 1);
				}else {
					OpenJob(i);
				}
				break;
			case 2:
				//가만있다가 후반에 직업공개
				if(AliveAll().size()>N/2) {
					Nothing(i);
				}else {
					OpenJob(i);
				}
				break;
			case 3:
				//가짜 직업 공개
				OpenJob(i);
				break;
			case 4:
				//적대인물 또는 랜덤 의견내기
				if(!Enemy.get(i).isEmpty()) {
					Suspect(i, RandomWho(Enemy.get(i), i), 2);
				}else {
					Suspect(i, RandomWho(Alive.get(1), i), 4);
				}
				break;
			}
		}
	}
	
	static void AI_Vote(int i) {
		List<Integer> list = new ArrayList<>();
		int[] temp;
		List<Integer> Temp;
		if(Alive.get(1).contains(i)) {
			//경찰인데 조사결과에 마피아 있으면, 무조건 투표 우선
			if(Job[i]==3) {
				for (int j = 0; j < find.length; j++) {
					if(find[j]==2 && Alive.get(2).contains(j)) {
						Vote(i, j);
						return;
					}
				}
			}
			//그 외
			switch (personal[i]) {
			case 1:
				//최다공론화(본인제외), 없으면 랜덤 투표
				temp = suspect_num.clone();
				temp[i]=0;
				Temp = FindMaxNum(temp);
				if(Temp.get(0)!=0) {
					Vote(i, Temp.get((int) (Math.random()*Temp.size())));
				}else {
					Vote(i, RandomWho(AliveAll(), i));
				}
				break;
			case 2:
				//최다공론화(본인제외), 없으면 랜덤 투표
				temp = suspect_num.clone();
				temp[i]=0;
				Temp = FindMaxNum(temp);
				if(Temp.get(0)!=0) {
					Vote(i, Temp.get((int) (Math.random()*Temp.size())));
				}else {
					Vote(i, RandomWho(AliveAll(), i));
				}
				break;
			case 3:
				//적대인물, 없으면 최다공론화
				if(!Enemy.get(i).isEmpty()) {
					Vote(i, RandomWho(Enemy.get(i), i));
				}else {
					temp = suspect_num.clone();
					temp[i]=0;
					Temp = FindMaxNum(temp);
					if(Temp.get(0)!=0) {
						Vote(i, Temp.get((int) (Math.random()*Temp.size())));
					}else {
						Vote(i, RandomWho(AliveAll(), i));
					}
				}
				break;
			case 4:
				//적대인물, 없으면 아무나
				if(!Enemy.get(i).isEmpty()) {
					Vote(i, RandomWho(Enemy.get(i), i));
				}else {
					Vote(i, RandomWho(AliveAll(), i));
				}
				break;
			}
		}else if(Alive.get(2).contains(i)) {
			switch (personal[i]) {
			case 1:
				//특수 직업, 랜덤 순으로 투표
				list = new ArrayList<>();
				for (int j = 0; j < Job_claim.length; j++) {
					if((Job_claim[j]==3 || Job_claim[j]==4) && Alive.get(1).contains(j) && i!=j) list.add(j);
				}
				if(!list.isEmpty()) {
					Vote(i, RandomWho(list, i));
				}else {
					Vote(i, RandomWho(Alive.get(1), i));
				}
				break;
			case 2:
				//최다공론화(본인제외, 같은 마피아 제외), 없으면 랜덤 투표
				temp = suspect_num.clone();
				for (int j = 0; j < Alive.get(2).size(); j++) {
					temp[Alive.get(2).get(j)] = 0;
				}
				Temp = FindMaxNum(temp);
				if(Temp.get(0)!=0) {
					Vote(i, Temp.get((int) (Math.random()*Temp.size())));
				}else {
					Vote(i, RandomWho(Alive.get(1), i));
				}
				break;
			case 3:
				//특수 직업, 적대인물, 랜덤 순으로 투표
				list = new ArrayList<>();
				for (int j = 0; j < Job_claim.length; j++) {
					if((Job_claim[j]==3 || Job_claim[j]==4) && Alive.get(1).contains(j) && i!=j) list.add(j);
				}
				if(!list.isEmpty()) {
					Vote(i, RandomWho(list, i));
				}else if(!Enemy.get(i).isEmpty()){
					Vote(i, RandomWho(Enemy.get(i), i));
				}else {
					Vote(i, RandomWho(Alive.get(1), i));
				}
				break;
			case 4:
				if(!Enemy.get(i).isEmpty()) {
					Vote(i, RandomWho(Enemy.get(i), i));
				}else {
					Vote(i, RandomWho(Alive.get(1), i));
				}
				break;
			}
		}
	}
	
	//본인 외 랜덤 인물
	static int RandomWho(List<Integer> list, int i) {
		int who;
		do {
			int rand = (int) (Math.random()*list.size());
			who = list.get(rand);
		} while (who==i);
		return who;
	}
	//현재 생존자 전체 목록
	static List<Integer> AliveAll(){
		List<Integer> list = new ArrayList<>();
		list.addAll(Alive.get(1));
		list.addAll(Alive.get(2));
		return list;
	}
	//가장 큰 번호 찾기
	static List<Integer> FindMaxNum(int[] list) {
		int max = 0;
		List<Integer> MaxNum = new ArrayList<>();
		for (int i = 0; i < list.length; i++) {
			if(list[i]>max) {
				max = list[i];
				MaxNum = new ArrayList<>();
			}
			if(list[i]==max) {
				MaxNum.add(i);
			}
		}
		MaxNum.sort(Comparator.reverseOrder());
		return MaxNum;
	}
	//가짜 직업활동
	static void FakeJob(int i) {
		//가짜 직업 선택
		if(Job_claim[i]==0) Job_claim[i]=(int) (Math.random()*2)+3;
		//특수 직업이라면
		if(Job_claim[i]==3 || Job_claim[i]==4) {
			//아무나 고르기
			pick_claim[i] = RandomWho(AliveAll(), i);
			//경찰 구라라면
			if(Job_claim[i]==3) {
				//특수직업 시민은 마피아로 몰기
				if((Job_claim[pick_claim[i]]==3 || Job_claim[pick_claim[i]]==4) && Alive.get(1).contains(pick_claim[i])){
					find_claim[pick_claim[i]] = 2;
				}else if(Alive.get(2).contains(pick_claim[i])) {
					//같은 마피아는 시민으로 몰기
					find_claim[pick_claim[i]] = 1;
				}else {
					//그 외는 랜덤
					if((int) (Math.random()*2) == 0) {
						find_claim[pick_claim[i]] = 1;
					}else {
						find_claim[pick_claim[i]] = 2;
					}
				}
			//의사 구라라면, 자힐 구라로 대체 가능	
			}else if(Job_claim[i]==4 && (int) (Math.random()*2) == 0) {
				pick_claim[i] = i;
			}
			
		}
	}

	
}
