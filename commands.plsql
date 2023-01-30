begin

  -- Thanks
  -- https://www.youtube.com/watch?v=xofpqdU3cD4

  -- Tables
  begin
    execute IMMEDIATE 'drop table students';
    execute IMMEDIATE 'drop table a';
    execute IMMEDIATE 'drop table departments';
  exception
    when others then
      null;
  end;

  create table a (a number);
  create table students (name varchar(100) NOT NULL,grade number(3) NOT NULL, dept_id number(2) NOT NULL);
  create table departments (dept_id number(2) NOT NULL, dept_name varchar(50), CONSTRAINT dept_id_pk PRIMARY KEY (dept_id));
  -- alter table students add constraint departments_dept_id_fk FOREIGN KEY (dept_id) REFERENCES departments(dept_id);

  insert all 
    into departments (dept_id, dept_name) values (1, 'IT')
    into departments (dept_id, dept_name) values (2, 'Statistic')
    into departments (dept_id, dept_name) values (3, 'Art')
  Select * from dual;

  Select * from departments;

  -- Loop
  declare
    i number;
  begin
    i:=1;
    loop
    dbms_output.put_line(i);
    insert into a values(i);
    i:=i+1;
    exit when i > 15;
    end loop;
  end;

  select * from a;

  -- Procedures
  create or replace procedure topperStudent
  as
    nameStudent students.name%type;
    gradeStudent students.grade%type;
  begin
    select name, grade into nameStudent, gradeStudent from students where grade=(select max(grade) from students);
    dbms_output.put_line('Name: ' || nameStudent || ' Grade: ' || gradeStudent);
  end;

  create or replace procedure fillStudents
  as
    name_array dbms_sql.varchar2_table;
    randomName number;
    randomGrade number;
    randomDepartment number;
  begin
    name_array(1) := 'David';
    name_array(2) := 'Daisy';
    name_array(3) := 'Max';
    name_array(4) := 'Tim';
    for i in 1..10 loop
        randomName := dbms_random.value(1, 4);
        randomDepartment := dbms_random.value(1, 3);
        randomGrade := dbms_random.value(1,100);
        insert into students values(name_array(randomName),randomGrade, randomDepartment);
    end loop;
  end;

  exec fillStudents;
  exec topperStudent;
  select * from students;


  -- Cursor - Implicit
  create or replace procedure updateGrades(gradeParameter in number default 0)
  as 
    var_rows number;
    newGrade number;
  begin
    if gradeParameter = 0 then
        newGrade := dbms_random.value(1,100);
    else
        newGrade := gradeParameter;
    end if;
    update students set grade=newGrade where grade<newGrade;
    if SQL%FOUND then
        var_rows :=SQL%ROWCOUNT;
        dbms_output.put_line('The grades of '|| var_rows || ' students were updated!');
    else
        dbms_output.put_line('There was a problem and nothing was found!');
    end if;
  end;

  exec updateGrades();
  select * from students;
  exec updateGrades(88);
  select * from students;

  delete from students;
  exec fillStudents;
  select * from students;


  -- Cursor Explicit
  declare cursor c1 is
    select D1.dept_name as department, avg(S1.grade) as avg_grade from departments D1 natural join students S1 group by D1.dept_name;
    rec1 c1%rowtype;
    begin
      for rec1 in c1 loop
        dbms_output.put_line(rec1.department ||' '||rec1.avg_grade);
      end loop;
  end;

  declare cursor c1 is
    select dept_name from departments;
  cursor c2(dept string) is
    select S1.name, S1.grade from students S1 natural join departments D1 where D1.dept_name=dept;
    rec1 c1%rowtype;
    rec2 c2%rowtype;
    begin
      for rec1 in c1 loop
        dbms_output.put_line(rec1.dept_name);
        for rec2 in c2(rec1.dept_name) loop
          dbms_output.put_line(rec2.name||' - '||rec2.grade);
        end loop;
        dbms_output.put_line(chr(10));
      end loop;
  end;

  create or replace procedure listStudents(dept varchar)
  is
    cursor c1 is
      select name,grade from students S1 natural join departments D1 where D1.dept_name=dept;
      rec1 c1%rowtype;
      begin
        for rec1 in c1 loop
          dbms_output.put_line(rec1.name||' Grade: '||rec1.grade);
        end loop;
  end;

  begin listStudents('IT'); end;


  -- Functions
  create or replace function qtdStudentsDepartment(dept varchar)
    return int is
      qtd int;
    begin
      select count(*) into qtd from students natural join departments where dept_name = dept;
      return qtd;
  end;
  select qtdStudentsDepartment('IT') from dual;

  create or replace function avgStudents
    return float is
      avg_grades float;
    begin
      select avg(grade) into avg_grades from students;
      return avg_grades;
  end;
  select avgStudents() from dual;


  -- Triggers
  create or replace trigger cleanStudents 
  after delete on departments for each row
  declare
    dept int;
  begin
    dept := :OLD.dept_id;
    delete from student where deptNo=dept;
  end;
  delete from departments where dept_id = 3;

  -- Package
  Create or replace package students_package
  as 
  procedure searchGrade(student_grade int);
  procedure insertStudent(nameStudent students.name%TYPE, gradeStudent students.grade%TYPE, deptStudent students.dept_id%TYPE);
  function highestGrade return students.grade%TYPE;
  end students_package;

  Create or replace package body students_package as
    procedure searchGrade(student_grade int) is
    cursor c1 is
        select name,dept_name, grade from students S1 natural join departments D1 where grade>student_grade;
        rec1 c1%rowtype;
        begin
          for rec1 in c1 loop
            dbms_output.put_line(rec1.name||' Dept: '|| rec1.dept_name || ' Grade: ' || rec1.grade);
          end loop;
        end searchGrade;

    procedure insertStudent(nameStudent students.name%TYPE, gradeStudent students.grade%TYPE, deptStudent students.dept_id%TYPE) is
      begin
        insert into students values(nameStudent,gradeStudent, deptStudent);
      end insertStudent;

    function highestGrade
      return students.grade%TYPE is
        hg students.grade%TYPE;
      begin
        select max(grade) into hg from students;
        return hg;
      end highestGrade;

    end students_package;

    exec students_package.searchGrade(60);
    exec students_package.insertStudent('Tom',90,1);
    exec students_package.searchGrade(60);
    select students_package.highestGrade() from dual;

    -- Exceptions
    declare
      dept INT;
      name departments.DEPT_NAME%Type;
      ex_invalid_dept EXCEPTION;
      ex_negative_dept EXCEPTION;
    begin
      dept := :userValue;
      if dept <=0 Then
        RAISE ex_negative_dept;
      elsif dept > 99 Then
        RAISE ex_invalid_dept;
      else
        Select dept_name into name from departments where dept_id = dept;
        dbms_output.put_line('Department: ' || name);
      end if;
    EXCEPTION
      When ex_invalid_dept then
        dbms_output.put_line('Department id must be less than 100!');
      When ex_negative_dept then
        dbms_output.put_line('Department id must be greater than zero!');
      When no_data_found then
        dbms_output.put_line('No such department!');
      When others then
        dbms_output.put_line('Error!');
    end;
end;